// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IVault.sol";

import "./utils/DefaultAccessControl.sol";

import "./libraries/external/FullMath.sol";

import "./VaultConfigurator.sol";

// TODO: events, tests, docs
contract Vault is IVault, ERC20, DefaultAccessControl, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant D9 = 1e9;

    IVaultConfigurator public immutable configurator;

    mapping(address => WithdrawalRequest) private _withdrawalRequest;
    EnumerableSet.AddressSet private _pendingWithdrawers;

    address[] private _underlyingTokens;
    EnumerableSet.AddressSet private _underlyingTokensSet;

    EnumerableSet.AddressSet private _tvlModules;

    function withdrawalRequest(
        address user
    ) external view returns (WithdrawalRequest memory) {
        return _withdrawalRequest[user];
    }

    function pendingWithdrawers() external view returns (address[] memory) {
        return _pendingWithdrawers.values();
    }

    function underlyingTokens() external view returns (address[] memory) {
        return _underlyingTokens;
    }

    function tvlModules() external view returns (address[] memory) {
        return _tvlModules.values();
    }

    function _calculateTvl(
        address[] memory tokens,
        bool isUnderlying
    ) private view returns (uint256[] memory amounts) {
        amounts = new uint256[](tokens.length);
        ITvlModule.Data[] memory data = _tvls();
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].isDebt) continue;
            for (uint256 j = 0; j < tokens.length; j++) {
                if (isUnderlying && data[i].underlyingToken == tokens[j]) {
                    amounts[j] += data[i].underlyingAmount;
                    break;
                }
                if (!isUnderlying && data[i].token == tokens[j]) {
                    amounts[j] += data[i].amount;
                    break;
                }
            }
        }
        for (uint256 i = 0; i < data.length; i++) {
            if (!data[i].isDebt) continue;
            for (uint256 j = 0; j < tokens.length; j++) {
                if (isUnderlying && data[i].underlyingToken == tokens[j]) {
                    if (amounts[j] < data[i].underlyingAmount)
                        revert InvalidState();
                    amounts[j] -= data[i].underlyingAmount;
                    break;
                }
                if (!isUnderlying && data[i].token == tokens[j]) {
                    if (amounts[j] < data[i].amount) revert InvalidState();
                    amounts[j] -= data[i].amount;
                    break;
                }
            }
        }
    }

    function underlyingTvl()
        public
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = _underlyingTokens;
        amounts = _calculateTvl(tokens, true);
    }

    function baseTvl()
        public
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        ITvlModule.Data[] memory data = _tvls();
        tokens = new address[](data.length);
        uint256 length = 0;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].token == address(0)) continue;
            uint256 tokenIndex = length;
            for (uint256 j = 0; j < length; j++) {
                if (tokens[j] == data[i].token) {
                    tokenIndex = j;
                    break;
                }
            }
            if (tokenIndex == length) {
                tokens[tokenIndex] = data[i].token;
                length++;
            }
        }
        assembly {
            mstore(tokens, length)
        }
        amounts = _calculateTvl(tokens, false);
    }

    function _tvls() private view returns (ITvlModule.Data[] memory data) {
        ITvlModule.Data[][] memory responses = new ITvlModule.Data[][](
            _tvlModules.length()
        );
        uint256 length = 0;
        for (uint256 i = 0; i < responses.length; i++) {
            address module = _tvlModules.at(i);
            responses[i] = ITvlModule(module).tvl(address(this));
            length += responses[i].length;
        }
        data = new ITvlModule.Data[](length);
        uint256 index = 0;
        for (uint256 i = 0; i < responses.length; i++) {
            for (uint256 j = 0; j < responses[i].length; j++) {
                data[index++] = responses[i][j];
            }
        }
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address admin
    ) ERC20(name_, symbol_) DefaultAccessControl(admin) {
        configurator = new VaultConfigurator();
    }

    function addToken(address token) external nonReentrant {
        _requireAdmin();
        if (_underlyingTokensSet.contains(token) || token == address(this))
            revert InvalidToken();
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

    function removeToken(address token) external nonReentrant {
        _requireAdmin();
        if (!_underlyingTokensSet.contains(token)) revert InvalidToken();
        (address[] memory tokens, uint256[] memory amounts) = underlyingTvl();
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

    function addTvlModule(address module) external nonReentrant {
        _requireAdmin();
        ITvlModule.Data[] memory data = ITvlModule(module).tvl(address(this));
        for (uint256 i = 0; i < data.length; i++) {
            if (!_underlyingTokensSet.contains(data[i].underlyingToken))
                revert InvalidToken();
            if (data[i].token == address(this)) revert InvalidToken();
            if (i > 0 && data[i].underlyingToken <= data[i - 1].underlyingToken)
                revert InvalidState();
        }
        _tvlModules.add(module);
    }

    function removeTvlModule(address module) external nonReentrant {
        _requireAdmin();
        if (!_tvlModules.contains(module)) revert InvalidState();
        _tvlModules.remove(module);
    }

    function externalCall(
        address to,
        bytes calldata data
    ) external nonReentrant returns (bool, bytes memory) {
        _requireAtLeastOperator();
        if (configurator.isDelegateModuleApproved(to)) revert Forbidden();
        IValidator validator = IValidator(configurator.validator());
        validator.validate(
            msg.sender,
            address(this),
            abi.encodeWithSelector(msg.sig, to, data)
        );
        validator.validate(address(this), to, data);
        return to.call(data);
    }

    function delegateCall(
        address to,
        bytes calldata data
    ) external returns (bool, bytes memory) {
        _requireAtLeastOperator();
        if (!configurator.isDelegateModuleApproved(to)) revert Forbidden();
        IValidator validator = IValidator(configurator.validator());
        validator.validate(
            msg.sender,
            address(this),
            abi.encodeWithSelector(msg.sig, to, data)
        );
        validator.validate(address(this), to, data);
        return to.delegatecall(data);
    }

    function deposit(
        address to,
        uint256[] memory amounts,
        uint256 minLpAmount,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256[] memory actualAmounts, uint256 lpAmount)
    {
        if (block.timestamp > deadline) revert Deadline();
        if (configurator.isDepositsLocked()) revert Forbidden();
        (
            address[] memory tokens,
            uint256[] memory totalAmounts
        ) = underlyingTvl();
        uint128[] memory ratiosX96 = IRatiosOracle(configurator.ratiosOracle())
            .getTargetRatiosX96(address(this));

        uint256 ratioX96 = type(uint256).max;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (ratiosX96[i] == 0) continue;
            uint256 ratioX96_ = FullMath.mulDiv(amounts[i], Q96, ratiosX96[i]);
            if (ratioX96_ < ratioX96) ratioX96 = ratioX96_;
        }
        if (ratioX96 == 0) revert ValueZero();

        uint256 depositValue = 0;
        uint256 totalValue = 0;
        actualAmounts = new uint256[](tokens.length);
        IPriceOracle priceOracle = IPriceOracle(configurator.priceOracle());
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 priceX96 = priceOracle.priceX96(address(this), tokens[i]);
            if (totalAmounts[i] > 0) {
                totalValue += FullMath.mulDiv(totalAmounts[i], priceX96, Q96);
            }
            if (ratiosX96[i] == 0) continue;
            uint256 amount = FullMath.mulDiv(ratioX96, ratiosX96[i], Q96);
            IERC20(tokens[i]).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            actualAmounts[i] = amount;
            depositValue += FullMath.mulDiv(amount, priceX96, Q96);
        }

        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            // scenario for initial deposit
            lpAmount = minLpAmount;
            if (lpAmount == 0) revert ValueZero();
            if (to != address(this)) revert Forbidden();
        } else {
            lpAmount = FullMath.mulDiv(depositValue, totalSupply, totalValue);
            if (lpAmount < minLpAmount) revert InsufficientLpAmount();
            if (to == address(0)) revert AddressZero();
        }

        if (lpAmount + totalSupply > configurator.maximalTotalSupply())
            revert LimitOverflow();
        _mint(to, lpAmount);

        address callback = configurator.depositCallback();
        if (callback != address(0)) {
            IDepositCallback(callback).depositCallback(actualAmounts, lpAmount);
        }
    }

    function emergencyWithdraw(
        uint256[] memory minAmounts
    ) external nonReentrant returns (uint256[] memory actualAmounts) {
        address sender = msg.sender;
        if (!_pendingWithdrawers.contains(sender)) revert InvalidState();
        uint256 timestamp = block.timestamp;
        WithdrawalRequest memory request = _withdrawalRequest[sender];
        if (
            timestamp > request.deadline ||
            request.lpAmount == 0 ||
            request.to == address(0)
        ) {
            _closeWithdrawalRequest(sender);
            return new uint256[](0);
        }

        if (
            request.timestamp + configurator.emergencyWithdrawalDelay() >
            timestamp
        ) revert InvalidState();

        uint256 totalSupply = totalSupply();
        (address[] memory tokens, uint256[] memory amounts) = baseTvl();
        if (minAmounts.length != tokens.length) revert InvalidLength();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (amounts[i] == 0) continue;
            uint256 amount = FullMath.mulDiv(
                IERC20(tokens[i]).balanceOf(address(this)),
                request.lpAmount,
                totalSupply
            );
            if (amount < minAmounts[i]) revert InsufficientAmount();
            IERC20(tokens[i]).safeTransfer(request.to, amount);
            actualAmounts[i] = amount;
        }
        _burn(address(this), request.lpAmount);
        delete _withdrawalRequest[sender];
        _pendingWithdrawers.remove(sender);
    }

    function cancleWithdrawalRequest() external nonReentrant {
        _closeWithdrawalRequest(msg.sender);
    }

    function _closeWithdrawalRequest(address sender) private {
        if (!_pendingWithdrawers.contains(sender)) return;
        WithdrawalRequest memory request = _withdrawalRequest[sender];
        delete _withdrawalRequest[sender];
        _pendingWithdrawers.remove(sender);
        _transfer(address(this), sender, request.lpAmount);
    }

    function registerWithdrawal(
        address to,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        uint256 deadline,
        bool closePrevious
    ) external nonReentrant {
        uint256 timestamp = block.timestamp;
        if (deadline < timestamp) revert Deadline();
        address sender = msg.sender;
        if (_pendingWithdrawers.contains(sender)) {
            if (closePrevious) {
                _closeWithdrawalRequest(sender);
            } else {
                revert InvalidState();
            }
        }
        uint256 balance = balanceOf(sender);
        if (lpAmount > balance) lpAmount = balance;
        if (lpAmount == 0) revert ValueZero();

        address[] memory tokens = _underlyingTokens;
        if (tokens.length != minAmounts.length) revert InvalidLength();

        _transfer(sender, address(this), lpAmount);
        _withdrawalRequest[sender] = WithdrawalRequest({
            to: to,
            lpAmount: lpAmount,
            tokens: tokens,
            minAmounts: minAmounts,
            deadline: deadline,
            timestamp: timestamp
        });
        _pendingWithdrawers.add(sender);
    }

    function processWithdrawals(
        address[] memory users
    ) external nonReentrant returns (bool[] memory statuses) {
        _requireAtLeastOperator();
        statuses = new bool[](users.length);
        ProcessWithdrawalsStack memory s = ProcessWithdrawalsStack({
            ratiosX96: IRatiosOracle(configurator.ratiosOracle())
                .getTargetRatiosX96(address(this)),
            amounts: new uint256[](0),
            totalValue: 0,
            ratiosX96Value: 0
        });
        address[] memory tokens;
        (tokens, s.amounts) = underlyingTvl();

        uint256[] memory erc20Balances = new uint256[](tokens.length);
        {
            IPriceOracle priceOracle = IPriceOracle(configurator.priceOracle());
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 priceX96 = priceOracle.priceX96(
                    address(this),
                    tokens[i]
                );
                s.totalValue += FullMath.mulDiv(s.amounts[i], priceX96, Q96);
                s.ratiosX96Value += FullMath.mulDiv(
                    s.ratiosX96[i],
                    priceX96,
                    Q96
                );
                erc20Balances[i] = IERC20(tokens[i]).balanceOf(address(this));
            }
        }
        uint256 totalSupply = totalSupply();
        uint256 burningSupply = 0;
        uint256 timestamp = block.timestamp;
        uint256 feeD9 = configurator.withdrawalFeeD9();
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            WithdrawalRequest memory request = _withdrawalRequest[user];
            if (
                request.tokens.length != tokens.length ||
                request.lpAmount == 0 ||
                request.deadline < timestamp
            ) {
                _closeWithdrawalRequest(user);
                continue;
            }

            uint256 coefficientX96;
            {
                uint256 withdrawalValue = FullMath.mulDiv(
                    request.lpAmount,
                    s.totalValue,
                    totalSupply
                );

                withdrawalValue = FullMath.mulDiv(
                    withdrawalValue,
                    D9 - feeD9,
                    D9
                );

                coefficientX96 = FullMath.mulDiv(
                    withdrawalValue,
                    Q96,
                    s.ratiosX96Value
                );
            }

            bool isWithdrawalPossible = true;
            uint256[] memory expectedAmounts = new uint256[](tokens.length);
            for (uint256 j = 0; j < tokens.length; j++) {
                if (request.tokens[j] != tokens[j]) {
                    isWithdrawalPossible = false;
                    break;
                }
                if (s.ratiosX96[j] != 0) {
                    expectedAmounts[j] = FullMath.mulDiv(
                        coefficientX96,
                        s.ratiosX96[j],
                        Q96
                    );
                }
                if (expectedAmounts[j] < request.minAmounts[j]) {
                    _closeWithdrawalRequest(user);
                    isWithdrawalPossible = false;
                    break;
                }
                if (erc20Balances[j] < expectedAmounts[j]) {
                    isWithdrawalPossible = false;
                    break;
                }
            }
            if (!isWithdrawalPossible) continue;

            for (uint256 j = 0; j < tokens.length; j++) {
                IERC20(tokens[j]).safeTransfer(request.to, expectedAmounts[j]);
                erc20Balances[j] -= expectedAmounts[j];
            }

            burningSupply += request.lpAmount;
            delete _withdrawalRequest[user];
            statuses[i] = true;
            _pendingWithdrawers.remove(user);
        }

        if (burningSupply > 0) _burn(address(this), burningSupply);

        address callback = configurator.withdrawalCallback();
        if (callback != address(0)) {
            IWithdrawalCallback(callback).withdrawalCallback();
        }
    }
}
