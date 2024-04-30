// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IVault.sol";

import "./utils/DefaultAccessControl.sol";

import "./libraries/external/FullMath.sol";

contract Vault is IVault, ERC20, DefaultAccessControl, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant D9 = 1e9;

    IRatiosOracle public immutable ratiosOracle;
    IOracle public immutable oracle;
    IValidator public immutable validator;
    IProtocolGovernance public immutable protocolGovernance;

    bool public isDepositsLocked;
    mapping(address => bytes) public tvlModuleParams;

    mapping(address => WithdrawalRequest) private _withdrawalRequest;
    address[] private _underlyingTokens;
    EnumerableSet.AddressSet private _withdrawers;
    EnumerableSet.AddressSet private _tvlModules;
    EnumerableSet.AddressSet private _underlyingTokensSet;

    modifier onlyManager() {
        if (!isOperator(msg.sender)) revert Forbidden();
        _;
    }

    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) revert Forbidden();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address admin,
        address protocolGovernance_,
        address ratiosOracle_,
        address oracle_,
        address validator_
    ) ERC20(name_, symbol_) DefaultAccessControl(admin) {
        if (ratiosOracle_ == address(0)) revert AddressZero();
        if (oracle_ == address(0)) revert AddressZero();
        if (validator_ == address(0)) revert AddressZero();
        if (protocolGovernance_ == address(0)) revert AddressZero();
        ratiosOracle = IRatiosOracle(ratiosOracle_);
        oracle = IOracle(oracle_);
        validator = IValidator(validator_);
        protocolGovernance = IProtocolGovernance(protocolGovernance_);
    }

    function lockDeposits() external onlyManager nonReentrant {
        isDepositsLocked = true;
    }

    function unlockDeposits() external onlyManager nonReentrant {
        isDepositsLocked = false;
    }

    function addToken(address token) external onlyAdmin nonReentrant {
        if (_underlyingTokensSet.contains(token)) return;
        _underlyingTokensSet.add(token);
        address[] storage tokens = _underlyingTokens;
        tokens.push(token);
        uint256 n = tokens.length;
        uint256 index = 0;
        for (uint256 i = 1; i < n; i++) {
            address token_ = tokens[n - 1 - i];
            if (token_ < token) {
                index = n - i;
                break;
            }
            tokens[n - i] = token_;
        }
        if (index < n - 1) tokens[index] = token;
    }

    function removeToken(address token) external onlyAdmin nonReentrant {
        if (!_underlyingTokensSet.contains(token)) revert InvalidToken();
        (address[] memory tokens, uint256[] memory amounts) = tvl();
        uint256 index = tokens.length;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                if (amounts[i] != 0) revert NonZeroValue();
                index = i;
                break;
            }
        }
        _underlyingTokensSet.remove(token);
        while (index + 1 < tokens.length) {
            _underlyingTokens[index] = tokens[index + 1];
            index++;
        }
        _underlyingTokens.pop();
    }

    function setTvlModule(
        address module,
        bytes memory params
    ) external onlyAdmin nonReentrant {
        (address[] memory tokens, uint256[] memory amounts) = ITvlModule(module)
            .tvl(address(this), params);
        if (tokens.length != amounts.length) revert InvalidState();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (!_underlyingTokensSet.contains(tokens[i]))
                revert InvalidToken();
            if (i > 0 && tokens[i] <= tokens[i - 1]) revert InvalidState();
        }
        _tvlModules.add(module);
        tvlModuleParams[module] = params;
    }

    function removeTvlModule(address module) external onlyAdmin nonReentrant {
        if (!_tvlModules.contains(module)) return;
        _tvlModules.remove(module);
        delete tvlModuleParams[module];
    }

    function externalCall(
        address to,
        bytes calldata data
    ) external onlyManager nonReentrant returns (bytes memory) {
        if (protocolGovernance.isDelegateModuleApproved(to)) revert Forbidden();
        if (protocolGovernance.isExternalCallsApproved(address(this)))
            revert Forbidden();
        validator.validate(address(this), to, data);
        (bool success, bytes memory response) = to.call(data);
        if (!success) revert InvalidState();
        return response;
    }

    /// @dev can be called in depositCallback or withdrawCallback
    function delegateCall(
        address to,
        bytes calldata data
    ) external onlyManager returns (bytes memory) {
        if (!protocolGovernance.isDelegateModuleApproved(to))
            revert Forbidden();
        validator.validate(address(this), to, data);
        (bool success, bytes memory response) = to.delegatecall(data);
        if (!success) revert InvalidState();
        return response;
    }

    function tvlModules() external view returns (address[] memory) {
        return _tvlModules.values();
    }

    function underlyingTokens() external view returns (address[] memory) {
        return _underlyingTokens;
    }

    function withdrawers() external view returns (address[] memory) {
        return _withdrawers.values();
    }

    function tvl()
        public
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = _underlyingTokens;
        amounts = new uint256[](tokens.length);
        address[] memory modules = _tvlModules.values();
        for (uint256 i = 0; i < modules.length; i++) {
            (address[] memory tokens_, uint256[] memory amounts_) = ITvlModule(
                modules[i]
            ).tvl(address(this), tvlModuleParams[modules[i]]);
            uint256 index = 0;
            for (uint256 j = 0; j < tokens_.length; j++) {
                while (index < tokens.length && tokens[index] != tokens_[j])
                    index++;
                if (index == tokens.length) revert InvalidToken();
                amounts[index++] += amounts_[j];
            }
        }
    }

    function deposit(
        uint256[] memory amounts,
        uint256 minLpAmount,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256[] memory actualAmounts, uint256 lpAmount)
    {
        if (block.timestamp > deadline) revert Deadline();
        if (isDepositsLocked) revert Forbidden();
        (address[] memory tokens, uint256[] memory totalAmounts) = tvl();
        uint256[] memory ratiosX96 = ratiosOracle.getTargetRatiosX96(
            address(this)
        );

        uint256 ratioX96 = type(uint256).max;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (ratiosX96[i] == 0) continue;
            uint256 ratioX96_ = FullMath.mulDiv(amounts[i], Q96, ratiosX96[i]);
            if (ratioX96_ < ratioX96) ratioX96 = ratioX96_;
        }

        uint256 depositValue = 0;
        uint256 totalValue = 0;
        actualAmounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (ratiosX96[i] == 0) continue;
            uint256 amount = FullMath.mulDiv(ratioX96, ratiosX96[i], Q96);
            IERC20(tokens[i]).transferFrom(msg.sender, address(this), amount);
            actualAmounts[i] = amount;

            uint256 priceX96 = oracle.priceX96(tokens[i]);
            depositValue += FullMath.mulDiv(amount, priceX96, Q96);
            totalValue += FullMath.mulDiv(totalAmounts[i], priceX96, Q96);
        }

        uint256 totalSupply = totalSupply();
        address to;
        if (totalSupply == 0) {
            lpAmount = minLpAmount;
            to = address(this);
        } else {
            lpAmount = FullMath.mulDiv(depositValue, totalSupply, totalValue);
            if (lpAmount < minLpAmount) revert InsufficientLpAmount();
            to = msg.sender;
        }
        if (
            lpAmount + totalSupply >
            protocolGovernance.maximalTotalSupply(address(this))
        ) revert LimitOverflow();
        _mint(to, lpAmount);

        address callback = protocolGovernance.depositCallback(address(this));
        if (callback != address(0)) {
            IDepositCallback(callback).depositCallback();
        }
    }

    function closeWithdrawalRequest() external nonReentrant {
        address sender = msg.sender;
        WithdrawalRequest memory request = _withdrawalRequest[sender];
        if (request.lpAmount == 0) return;
        delete _withdrawalRequest[sender];
        _withdrawers.remove(sender);
        _transfer(address(this), sender, request.lpAmount);
    }

    function registerWithdrawal(
        address to,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        uint256 deadline
    ) external nonReentrant {
        if (deadline < block.timestamp) revert Deadline();
        if (_withdrawalRequest[msg.sender].lpAmount != 0) revert InvalidState();
        {
            uint256 balance = balanceOf(msg.sender);
            if (lpAmount > balance) lpAmount = balance;
        }
        if (lpAmount == 0) return;

        address[] memory tokens = _underlyingTokens;
        if (tokens.length != minAmounts.length) revert InvalidLength();

        _transfer(msg.sender, address(this), lpAmount);

        _withdrawalRequest[msg.sender] = WithdrawalRequest({
            to: to,
            lpAmount: lpAmount,
            tokens: tokens,
            minAmounts: minAmounts,
            deadline: deadline
        });
        _withdrawers.add(msg.sender);
    }

    function withdrawalRequest(
        address user
    ) external view returns (WithdrawalRequest memory) {
        return _withdrawalRequest[user];
    }

    function processWithdrawals(
        address[] memory users
    ) external nonReentrant onlyManager returns (bool[] memory statuses) {
        statuses = new bool[](users.length);
        ProcessWithdrawalsStorage memory s;
        s.ratiosX96 = ratiosOracle.getTargetRatiosX96(address(this));
        address[] memory tokens;
        (tokens, s.amounts) = tvl();

        uint256[] memory erc20Balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 priceX96 = oracle.priceX96(tokens[i]);
            s.totalValue += FullMath.mulDiv(s.amounts[i], priceX96, Q96);
            s.x96Value += FullMath.mulDiv(s.ratiosX96[i], priceX96, Q96);
            erc20Balances[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        uint256 totalSupply = totalSupply();
        uint256 timestamp = block.timestamp;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            WithdrawalRequest memory request = _withdrawalRequest[user];
            if (
                request.tokens.length != tokens.length ||
                request.lpAmount == 0 ||
                request.deadline < timestamp
            ) continue;

            uint256 withdrawalValue = FullMath.mulDiv(
                request.lpAmount,
                s.totalValue,
                totalSupply
            );
            withdrawalValue = FullMath.mulDiv(
                withdrawalValue,
                D9 - protocolGovernance.withdrawalFeeD9(address(this)),
                D9
            );

            uint256 ratioX96 = FullMath.mulDiv(
                withdrawalValue,
                Q96,
                s.x96Value
            );
            bool isEnoughTokens = true;
            uint256[] memory expectedAmounts = new uint256[](tokens.length);

            for (uint256 j = 0; j < tokens.length; j++) {
                if (request.tokens[j] != tokens[j]) {
                    isEnoughTokens = false;
                    break;
                }
                if (s.ratiosX96[j] != 0) {
                    expectedAmounts[j] = FullMath.mulDiv(
                        ratioX96,
                        s.ratiosX96[j],
                        Q96
                    );
                }
                if (
                    expectedAmounts[j] < request.minAmounts[j] ||
                    erc20Balances[j] < expectedAmounts[j]
                ) {
                    isEnoughTokens = false;
                    break;
                }
            }
            if (!isEnoughTokens) continue;

            for (uint256 j = 0; j < tokens.length; j++) {
                IERC20(tokens[j]).safeTransfer(request.to, expectedAmounts[j]);
                erc20Balances[j] -= expectedAmounts[j];
            }

            _burn(address(this), request.lpAmount);
            delete _withdrawalRequest[user];
            statuses[i] = true;
            _withdrawers.remove(user);
        }

        address callback = protocolGovernance.withdrawalCallback(address(this));
        if (callback != address(0)) {
            IWithdrawalCallback(callback).withdrawalCallback();
        }
    }
}
