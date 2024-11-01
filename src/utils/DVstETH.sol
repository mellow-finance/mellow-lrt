// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/Address.sol";
import "../Vault.sol";
import "../modules/obol/MutableStakingModule.sol";

contract DVstETH is Vault {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant wsteth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    // Delay for permissionless withdrawal processing
    uint256 public withdrawalDelay;

    // Reference to the staking module for staking operations
    IMutableStakingModule public stakingModule;

    constructor() Vault("", "", address(0xdead)) {}

    modifier deprecated() {
        revert("DVstETH: DEPRECATED");
        _;
    }

    /// ------------------ EXTERNAL MUTABLE GOVERNANCE FUNCTIONS ------------------ ///

    /// @notice Set the delay for permissionless withdrawals
    /// @param newWithdrawalDelay The delay in seconds
    function setWithdrawalDelay(uint256 newWithdrawalDelay) external {
        _requireAdmin();
        require(newWithdrawalDelay != 0, "DVstETH: INVALID_WITHDRAWAL_DELAY");
        withdrawalDelay = newWithdrawalDelay;
    }

    /// @param module Address of the new staking module
    function setStakingModule(address module) external {
        _requireAdmin();
        /// @dev Verifies module approval using the VaultConfigurator’s isDelegateModuleApproved field.
        require(
            module == address(0) ||
                configurator.isDelegateModuleApproved(module),
            "DVstETH: STAKING_MODULE_NOT_APPROVED"
        );
        stakingModule = IMutableStakingModule(module);
    }

    /// @notice Allows operator to stake specified amount of ETH to stETH
    /// @param amount The amount to submit
    function submit(uint256 amount) external {
        _requireAtLeastOperator();
        _submit(amount);
    }

    /// @notice Allows to permissionlessly stake the amount of ETH to stETH calculated by the staking module
    function submitPermissionless() external {
        _submit(stakingModule.getAmountForPermissionlessStake());
    }

    /// NOTE: This function is used for permissionless staking and depositing
    /// @notice Submits assets and deposits them into Lido DSM (or directly in specified submodules) using staking module functionality
    /// @param data Encoded data for staking and depositing
    function submitAndDeposit(bytes calldata data) external {
        IMutableStakingModule stakingModule_ = stakingModule;
        uint256 amount = stakingModule_.getAmountForStakeAndDeposit(data);
        _submit(amount);
        stakingModule_.depositOnBehalf(data, amount, msg.sender);
    }

    /// ------------------ EXTERNAL MUTABLE OVERRIDE FUNCTIONS ------------------ ///

    /// NOTE: no whitelist logic
    /// @inheritdoc IVault
    function deposit(
        address to,
        uint256[] calldata amounts,
        uint256 minLpAmount,
        uint256 deadline,
        uint256 referralCode
    )
        external
        payable
        override
        nonReentrant
        checkDeadline(deadline)
        returns (uint256[] memory actualAmounts, uint256 lpAmount)
    {
        require(!configurator.isDepositLocked(), "DVstETH: DEPOSIT_IS_LOCKED");
        require(
            amounts.length == 2 && amounts[0] == 0 && amounts[1] != 0,
            "DVstETH: INVALID_DEPOSIT_AMOUNTS"
        );

        uint256 amount = amounts[1];
        address this_ = address(this);
        if (msg.value == amount) {
            // Handling direct ETH deposit, converts to WETH
            IWeth(weth).deposit{value: amount}();
        } else {
            // Handling WETH deposit
            require(msg.value == 0, "DVstETH: INVALID_MSG_VALUE");
            IERC20(weth).safeTransferFrom(msg.sender, this_, amount);
        }

        // `getStETHByWstETH` converts wstETH to stETH with rounding down.
        // Adding 1 wei to the computed total to prevent underestimation in deposit calculations.
        uint256 totalAssets = IERC20(weth).balanceOf(this_) +
            IWSteth(wsteth).getStETHByWstETH(IERC20(wsteth).balanceOf(this_)) +
            1 wei;
        uint256 totalSupply_ = totalSupply();
        lpAmount = amount.mulDiv(totalSupply_, totalAssets);
        require(
            totalSupply_ + lpAmount <= configurator.maximalTotalSupply(),
            "DVstETH: EXCEEDS_MAXIMAL_TOTAL_SUPPLY_LIMIT"
        );
        require(lpAmount >= minLpAmount, "DVstETH: INSUFFICIENT_LP_AMOUNT");
        _mint(to, lpAmount);
        actualAmounts = amounts;
        emit Deposit(to, amounts, lpAmount, referralCode);
    }

    /// @inheritdoc IVault
    function processWithdrawals(
        address[] calldata users
    ) external override nonReentrant returns (bool[] memory statuses) {
        uint256 timestamp = block.timestamp;
        uint256 latestTimestamp = timestamp -
            (isOperator(msg.sender) ? 0 : withdrawalDelay);
        statuses = new bool[](users.length);
        address this_ = address(this);
        uint256 totalSupply_ = totalSupply();
        uint256 wstethBalance = IERC20(wsteth).balanceOf(this_);
        uint256 wethBalance = IERC20(weth).balanceOf(this_);
        uint256 totalAssets_ = wstethBalance +
            IWSteth(wsteth).getWstETHByStETH(wethBalance);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            WithdrawalRequest memory request = _withdrawalRequest[user];
            if (request.lpAmount == 0 || request.timestamp > latestTimestamp) {
                // Skips if no withdrawal request or if request not ready for processing
                continue;
            }
            uint256 amount = totalAssets_.mulDiv(
                request.lpAmount,
                totalSupply_
            );
            if (amount > wstethBalance) {
                // Skips if insufficient wstETH to cover the withdrawal
                continue;
            }
            if (
                timestamp > request.deadline ||
                amount < request.minAmounts[0] ||
                request.minAmounts[1] != 0
            ) {
                // Cancels the withdrawal request if deadline has passed, stETH amount is less than min,
                // or unexpected WETH amount is specified
                _cancelWithdrawalRequest(user);
                continue;
            }
            delete _withdrawalRequest[user];
            _pendingWithdrawers.remove(user);
            wstethBalance -= amount;
            totalAssets_ -= amount;
            _burn(this_, request.lpAmount);
            statuses[i] = true;
            IERC20(wsteth).safeTransfer(request.to, amount);
        }

        emit WithdrawalsProcessed(users, statuses);
    }

    /// @notice Fallback function to accept ETH, only from the WETH contract
    receive() external payable override {
        require(msg.sender == weth, "DVstETH: INVALID_SENDER");
    }

    /// ------------------ INTERNAL MUTABLE FUNCTIONS ------------------ ///

    /// @notice Converts WETH to stETH and stakes it
    /// @param amount Amount to stake
    function _submit(uint256 amount) private {
        IWeth(weth).withdraw(amount);
        Address.sendValue(payable(wsteth), amount);
    }

    /// ------------------ BACKWARD COMPATIBILITY ------------------ ///

    /// @inheritdoc IVault
    function underlyingTvl()
        public
        view
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = _underlyingTokens;
        amounts = new uint256[](2);
        address this_ = address(this);
        amounts[0] = IERC20(wsteth).balanceOf(this_);
        amounts[1] = IERC20(weth).balanceOf(this_);
    }

    /// @inheritdoc IVault
    function baseTvl()
        public
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        return underlyingTvl();
    }

    /// @inheritdoc IVault
    function analyzeRequest(
        ProcessWithdrawalsStack memory s,
        WithdrawalRequest memory request
    )
        public
        view
        override
        returns (bool, bool, uint256[] memory expectedAmounts)
    {
        uint256 lpAmount = request.lpAmount;
        if (request.deadline < s.timestamp)
            return (false, false, expectedAmounts);
        uint256 totalValue = s.erc20Balances[0] +
            IWSteth(wsteth).getWstETHByStETH(s.erc20Balances[1]);
        expectedAmounts = new uint256[](2);
        expectedAmounts[0] = totalValue.mulDiv(lpAmount, s.totalSupply);
        if (request.minAmounts[0] > expectedAmounts[0])
            return (false, false, expectedAmounts);
        if (s.erc20Balances[0] < expectedAmounts[0])
            return (true, false, expectedAmounts);
        return (true, true, expectedAmounts);
    }

    /// @inheritdoc IVault
    function calculateStack()
        public
        view
        override
        returns (ProcessWithdrawalsStack memory s)
    {
        (s.tokens, s.erc20Balances) = underlyingTvl();
        s.ratiosX96 = new uint128[](2); // withdrawal ratios
        s.ratiosX96[0] = 2 ** 96;
        s.totalSupply = totalSupply();
        s.totalValue =
            IWSteth(wsteth).getStETHByWstETH(s.erc20Balances[0]) +
            s.erc20Balances[1];
        s.timestamp = block.timestamp;
        s.tokensHash = keccak256(abi.encode(s.tokens));
    }

    /// @inheritdoc IVault
    function addToken(address) external pure override deprecated {}

    /// @inheritdoc IVault
    function removeToken(address) external pure override deprecated {}

    /// @inheritdoc IVault
    function addTvlModule(address) external pure override deprecated {}

    /// @inheritdoc IVault
    function removeTvlModule(address) external pure override deprecated {}

    /// @inheritdoc IVault
    function externalCall(
        address,
        bytes calldata
    ) external pure override deprecated returns (bool, bytes memory) {}

    /// @inheritdoc IVault
    function delegateCall(
        address,
        bytes calldata
    ) external pure override deprecated returns (bool, bytes memory) {}
}
