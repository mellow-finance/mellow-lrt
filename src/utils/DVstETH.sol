// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/IVault.sol";
import "../interfaces/modules/obol/IStakingModule.sol";
import "./DefaultAccessControl.sol";

interface IMutableStakingModule {
    /*
        Logic:
        1. get available keys
        2. get depositable ether
        3. calculate available amount of ETH for staking
        4. revert if zero
    */
    function getAmountForStake(
        bytes calldata data
    ) external view returns (uint256 amount); // revert if not in the right state
}

contract DVstETH is ERC20, DefaultAccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wsteth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    /*
        Storage slots:

        inheritances:
        0-4: ERC20 - first slots [0-4]
        5-6: DefaultAccessControl - first slots [5-6]
        7: ReentrancyGuard - first slots [7]

        own and reserved (deprecated) slots:
        8: IVaultConfigurator public configurator
        9: mapping(address => IVault.WithdrawalRequest) withdrawalRequests;
        10-11: _pendingWithdrawers  - EnumerableSet.AddressSet.(bytes32[])_values
        12: NOTE: _reserved1[0]  - address[] private _underlyingTokens;
        13: NOTE: _reserved1[1]  - mapping(address => bool) private _isUnderlyingToken;
        14-15: NOTE: _reserved1[2]  - EnumerableSet.AddressSet.(bytes32[])_values private _tvlModules;
    */

    IVaultConfigurator public configurator; // backward compatibility
    mapping(address => IVault.WithdrawalRequest) private _withdrawalRequest;
    EnumerableSet.AddressSet private _pendingWithdrawers;
    address[] private _underlyingTokens; // backward compatibility
    mapping(address => bool) private _isUnderlyingToken; // backward compatibility
    EnumerableSet.AddressSet private _tvlModules; // backward compatibility
    uint256 public withdrawalDelay;
    uint256 public totalSupplyLimit;
    uint256 public emergencyWithdrawalDelay;
    address public stakingModule;

    // singleton constructor
    constructor() ERC20("", "") DefaultAccessControl(address(0xdead)) {}

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "DVstETH: EXPIRED");
        _;
    }

    function setWithdrawalDelay(uint256 newWithdrawalDelay) external {
        _requireAdmin();
        require(newWithdrawalDelay != 0, "DVstETH: INVALID_WITHDRAWAL_DELAY");
        withdrawalDelay = newWithdrawalDelay;
    }

    // NOTE: high impact
    function setStakingModule(address newStakingModule) external {
        _requireAdmin();
        stakingModule = newStakingModule;
    }

    // NOTE: no stage-commit logic
    function setTotalSupplyLimit(uint256 newTotalSupplyLimit) external {
        _requireAdmin();
        totalSupplyLimit = newTotalSupplyLimit;
    }

    // NOTE: no stage-commit logic
    function setEmergencyWithdrawalDelay(
        uint256 newEmergencyWithdrawalDelay
    ) external {
        _requireAdmin();
        emergencyWithdrawalDelay = newEmergencyWithdrawalDelay;
    }

    // NOTE: no deposit whitelist
    function deposit(
        address to,
        uint256[] calldata amounts,
        uint256 minLpAmount,
        uint256 deadline,
        uint256 referralCode
    )
        public
        payable
        nonReentrant
        checkDeadline(deadline)
        returns (uint256 lpAmount)
    {
        require(
            amounts.length == 2 && amounts[0] == 0 && amounts[1] != 0,
            "DVstETH: INVALID_DEPOSIT_AMOUNTS"
        );
        uint256 amount = amounts[1];
        address this_ = address(this);
        if (msg.value == amount) {
            // eth deposit
            IWeth(weth).deposit{value: amount}();
        } else {
            // weth deposit
            require(msg.value == 0, "DVstETH: INVALID_MSG_VALUE");
            IERC20(weth).safeTransferFrom(msg.sender, this_, amount);
        }
        uint256 totalAssets = IERC20(weth).balanceOf(this_) +
            IWSteth(wsteth).getStETHByWstETH(IERC20(wsteth).balanceOf(this_));
        uint256 totalSupply_ = totalSupply();
        lpAmount = amount.mulDiv(totalSupply_, totalAssets);
        require(
            totalSupply_ + lpAmount <= totalSupplyLimit,
            "DVstETH: EXCEEDS_MAXIMAL_TOTAL_SUPPLY_LIMIT"
        );
        require(lpAmount >= minLpAmount, "DVstETH: INSUFFICIENT_LP_AMOUNT");
        _mint(to, lpAmount);
        emit IVault.Deposit(to, amounts, lpAmount, referralCode);
    }

    function submit(uint256 amount) external {
        _requireAtLeastOperator();
        _submit(amount);
    }

    // NOTE: permissionless function
    function submit(bytes calldata data) external {
        _submit(IMutableStakingModule(stakingModule).getAmountForStake(data));
    }

    function _submit(uint256 amount) private {
        IWeth(weth).withdraw(amount);
        // TODO: replace with IWSteth(wsteth).submit{value: amount}(address(0));
        ISteth(steth).submit{value: amount}(address(0));
        IERC20(steth).safeIncreaseAllowance(address(wsteth), amount);
        IWSteth(wsteth).wrap(amount);
    }

    function registerWithdrawal(
        address to,
        uint256 lpAmount,
        uint256[] calldata minAmounts,
        uint256 deadline,
        uint256 requestDeadline,
        bool overridePrevious
    )
        external
        nonReentrant
        checkDeadline(deadline)
        checkDeadline(requestDeadline)
    {
        require(
            minAmounts.length == 2 && minAmounts[0] != 0 && minAmounts[1] == 0,
            "DVstETH: INVALID_MIN_AMOUNTS"
        );
        address sender = msg.sender;
        address this_ = address(this);
        uint256 existingRequest = 0;
        if (!_pendingWithdrawers.add(sender)) {
            require(
                overridePrevious,
                "DVstETH: PREVIOUS_WITHDRAWAL_REQUEST_EXISTS"
            );
            existingRequest = _withdrawalRequest[sender].lpAmount;
            emit IVault.WithdrawalRequestCanceled(sender, tx.origin);
        }
        lpAmount = lpAmount.min(balanceOf(sender) + existingRequest);
        require(lpAmount != 0, "DVstETH: INSUFFICIENT_LP_AMOUNT");
        if (existingRequest > lpAmount) {
            _transfer(this_, sender, existingRequest - lpAmount);
        } else if (existingRequest < lpAmount) {
            _transfer(sender, this_, lpAmount - existingRequest);
        }
        _withdrawalRequest[sender] = IVault.WithdrawalRequest({
            to: to,
            lpAmount: lpAmount,
            tokensHash: bytes32(0),
            minAmounts: minAmounts,
            deadline: deadline,
            timestamp: block.timestamp
        });
        emit IVault.WithdrawalRequested(sender, _withdrawalRequest[sender]);
    }

    function cancelWithdrawalRequest() external nonReentrant {
        _cancelWithdrawalRequest(msg.sender);
    }

    function _cancelWithdrawalRequest(address sender) private {
        require(
            _pendingWithdrawers.remove(sender),
            "DVstETH: NO_WITHDRAWAL_REQUEST"
        );
        IVault.WithdrawalRequest memory request = _withdrawalRequest[sender];
        delete _withdrawalRequest[sender];
        _transfer(address(this), sender, request.lpAmount);
        emit IVault.WithdrawalRequestCanceled(sender, tx.origin);
    }

    function emergencyWithdraw(
        uint256[] calldata minAmounts,
        uint256 deadline
    )
        external
        nonReentrant
        checkDeadline(deadline)
        returns (uint256[] memory actualAmounts)
    {
        require(minAmounts.length == 2, "DVstETH: INVALID_MIN_AMOUNTS");
        uint256 timestamp = block.timestamp;
        address sender = msg.sender;
        address this_ = address(this);
        IVault.WithdrawalRequest memory request = _withdrawalRequest[sender];
        require(request.lpAmount != 0, "DVstETH: NO_WITHDRAWAL_REQUEST");
        if (timestamp > request.deadline) {
            _cancelWithdrawalRequest(sender);
            return actualAmounts;
        }
        require(
            request.timestamp + emergencyWithdrawalDelay >= timestamp,
            "DVstETH: EMERGENCY_WITHDRAWAL_DELAY"
        );

        uint256 totalSupply_ = totalSupply();
        actualAmounts = new uint256[](2);
        actualAmounts[0] = Math.mulDiv(
            IERC20(wsteth).balanceOf(this_),
            request.lpAmount,
            totalSupply_
        );
        actualAmounts[1] = Math.mulDiv(
            IERC20(weth).balanceOf(this_),
            request.lpAmount,
            totalSupply_
        );

        require(
            actualAmounts[0] >= minAmounts[0] &&
                actualAmounts[1] >= minAmounts[1],
            "DVstETH: INSUFFICIENT_AMOUNTS"
        );

        IERC20(wsteth).safeTransfer(request.to, actualAmounts[0]);
        IERC20(weth).safeTransfer(request.to, actualAmounts[1]);

        delete _withdrawalRequest[sender];
        _pendingWithdrawers.remove(sender);
        _burn(this_, request.lpAmount);
        emit IVault.EmergencyWithdrawal(sender, request, actualAmounts);
    }

    function processWithdrawals(
        address[] calldata users
    ) external nonReentrant returns (bool[] memory statuses) {
        uint256 latestTimestamp = block.timestamp -
            (isOperator(msg.sender) ? 0 : withdrawalDelay);
        statuses = new bool[](users.length);
        address this_ = address(this);
        uint256 totalSupply_ = totalSupply();
        uint256 wstethBalance = IERC20(wsteth).balanceOf(this_);
        uint256 wethBalance = IERC20(weth).balanceOf(this_);
        uint256 totalAssets_ = wstethBalance +
            IWSteth(wsteth).getStETHByWstETH(wethBalance);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            IVault.WithdrawalRequest memory request = _withdrawalRequest[user];
            if (request.lpAmount == 0 || request.timestamp > latestTimestamp) {
                continue;
            }
            uint256 amount = totalAssets_.mulDiv(
                request.lpAmount,
                totalSupply_
            );
            if (amount > wstethBalance) {
                continue;
            }
            _pendingWithdrawers.remove(user);
            if (
                block.timestamp > request.deadline ||
                amount < request.minAmounts[0]
            ) {
                _cancelWithdrawalRequest(user);
                continue;
            }
            wstethBalance -= amount;
            totalAssets_ -= amount;
            _burn(this_, request.lpAmount);
            IERC20(wsteth).safeTransfer(request.to, amount);
            statuses[i] = true;
            delete _withdrawalRequest[user];
        }

        emit IVault.WithdrawalsProcessed(users, statuses);
    }

    receive() external payable {
        require(msg.sender == weth, "DVstETH: INVALID_SENDER");
    }

    // -------- BACKWARD COMPATIBILITY --------

    function withdrawalRequest(
        address user
    ) external view returns (IVault.WithdrawalRequest memory) {
        return _withdrawalRequest[user];
    }

    function pendingWithdrawersCount() external view returns (uint256) {
        return _pendingWithdrawers.length();
    }

    function pendingWithdrawers(
        uint256 limit,
        uint256 offset
    ) external view returns (address[] memory result) {
        EnumerableSet.AddressSet storage withdrawers_ = _pendingWithdrawers;
        uint256 count = withdrawers_.length();
        if (offset >= count || limit == 0) return result;
        count -= offset;
        if (count > limit) count = limit;
        result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = withdrawers_.at(offset + i);
        }
        return result;
    }

    function pendingWithdrawers() external view returns (address[] memory) {
        return _pendingWithdrawers.values();
    }

    function calculateStack()
        public
        view
        returns (IVault.ProcessWithdrawalsStack memory stack)
    {
        address this_ = address(this);
        stack.tokens = new address[](2);
        stack.tokens[0] = wsteth;
        stack.tokens[1] = weth;
        stack.ratiosX96 = new uint128[](2); // withdrawal ratios
        stack.ratiosX96[0] = 2 ** 96;
        stack.erc20Balances = new uint256[](2);
        stack.erc20Balances[0] = IERC20(wsteth).balanceOf(this_);
        stack.erc20Balances[1] = IERC20(weth).balanceOf(this_);
        stack.totalSupply = totalSupply();
        stack.totalValue =
            IWSteth(wsteth).getStETHByWstETH(stack.erc20Balances[0]) +
            stack.erc20Balances[1];
        stack.timestamp = block.timestamp;
        stack.tokensHash = keccak256(abi.encode(stack.tokens));
    }
}
