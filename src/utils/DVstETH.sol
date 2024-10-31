// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../Vault.sol";
import "../modules/obol/MutableStakingModule.sol";

contract DVstETH is Vault {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wsteth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    uint256 public withdrawalDelay = 1 hours;
    uint256 public totalSupplyLimit = 10000 ether;
    uint256 public emergencyWithdrawalDelay = 90 days;
    address public stakingModule;

    constructor() Vault("", "", address(0xdead)) {}

    modifier depreacted() {
        revert("DVstETH: DEPRECATED");
        _;
    }

    /// ------------------ EXTERNAL MUTABLE GOVERNANCE FUNCTIONS ------------------ ///

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

    function submit(uint256 amount) external {
        _requireAtLeastOperator();
        _submit(amount);
    }

    // NOTE: permissionless function
    function submit(bytes calldata data) external {
        _submit(IMutableStakingModule(stakingModule).getAmountForStake(data));
    }

    /// ------------------ EXTERNAL VIEW OVERRIDE FUNCTIONS ------------------ ///

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

    /// ------------------ DEPRECATED FUNCTIONS ------------------ ///

    /// @inheritdoc IVault
    function addToken(address) external pure override depreacted {}

    /// @inheritdoc IVault
    function removeToken(address) external pure override depreacted {}

    /// @inheritdoc IVault
    function addTvlModule(address) external pure override depreacted {}

    /// @inheritdoc IVault
    function removeTvlModule(address) external pure override depreacted {}

    /// @inheritdoc IVault
    function externalCall(
        address,
        bytes calldata
    ) external pure override depreacted returns (bool, bytes memory) {}

    /// @inheritdoc IVault
    function delegateCall(
        address,
        bytes calldata
    ) external pure override depreacted returns (bool, bytes memory) {}

    /// ------------------ EXTERNAL MUTABLE FUNCTIONS ------------------ ///

    // NOTE: no deposit whitelist
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
        actualAmounts = amounts;
        emit IVault.Deposit(to, amounts, lpAmount, referralCode);
    }

    /// @inheritdoc IVault
    function registerWithdrawal(
        address to,
        uint256 lpAmount,
        uint256[] calldata minAmounts,
        uint256 deadline,
        uint256 requestDeadline,
        bool overridePrevious
    )
        external
        override
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
            tokensHash: keccak256(abi.encode(_underlyingTokens)),
            minAmounts: minAmounts,
            deadline: deadline,
            timestamp: block.timestamp
        });
        emit IVault.WithdrawalRequested(sender, _withdrawalRequest[sender]);
    }

    /// @inheritdoc IVault
    function emergencyWithdraw(
        uint256[] calldata minAmounts,
        uint256 deadline
    )
        external
        override
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
        actualAmounts[0] = request.lpAmount.mulDiv(
            IERC20(wsteth).balanceOf(this_),
            totalSupply_
        );
        actualAmounts[1] = request.lpAmount.mulDiv(
            IERC20(weth).balanceOf(this_),
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

    /// @inheritdoc IVault
    function processWithdrawals(
        address[] calldata users
    ) external override nonReentrant returns (bool[] memory statuses) {
        uint256 latestTimestamp = block.timestamp -
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

    receive() external payable override {
        require(msg.sender == weth, "DVstETH: INVALID_SENDER");
    }

    /// ------------------ INTERNAL MUTABLE OVERRIDE FUNCTIONS ------------------ ///

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        ERC20._update(from, to, value);
    }

    function _submit(uint256 amount) private {
        IWeth(weth).withdraw(amount);
        // TODO: replace with IWSteth(wsteth).submit{value: amount}(address(0));
        ISteth(steth).submit{value: amount}(address(0));
        IERC20(steth).safeIncreaseAllowance(address(wsteth), amount);
        IWSteth(wsteth).wrap(amount);
    }
}
