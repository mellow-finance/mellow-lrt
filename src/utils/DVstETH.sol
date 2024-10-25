// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/IVault.sol";
import "./DefaultAccessControl.sol";
import "../interfaces/modules/obol/IStakingModule.sol";

interface IMutableStakingModule {
    function getDepositableEtherOrRevert(
        bytes calldata data
    ) external view returns (uint256 amount); // revert if not in the right state
    function deposit(bytes calldata data) external; // deposits amount of ether into SDVT Module
}

contract DVstETHStakingModuleV2 is IMutableStakingModule {
    address public immutable weth;
    address public immutable steth;
    address public immutable wsteth;
    ILidoLocator public immutable lidoLocator;
    IWithdrawalQueue public immutable withdrawalQueue;
    uint256 public immutable stakingModuleId;

    constructor(
        address weth_,
        address steth_,
        address wsteth_,
        ILidoLocator lidoLocator_,
        IWithdrawalQueue withdrawalQueue_,
        uint256 stakingModuleId_
    ) {
        weth = weth_;
        steth = steth_;
        wsteth = wsteth_;
        lidoLocator = lidoLocator_;
        withdrawalQueue = withdrawalQueue_;
        stakingModuleId = stakingModuleId_;
    }

    struct Data {
        uint256 blockNumber;
        bytes32 blockHash;
        bytes32 depositRoot;
        uint256 nonce;
        bytes depositCalldata;
        IDepositSecurityModule.Signature[] sortedGuardianSignatures;
    }

    function getDepositableEtherOrRevert(
        bytes calldata data_
    ) external view returns (uint256 amount) {
        Data memory data = abi.decode(data_, (Data));
        IDepositSecurityModule depositSecurityModule = IDepositSecurityModule(
            lidoLocator.depositSecurityModule()
        );
        if (
            IDepositContract(depositSecurityModule.DEPOSIT_CONTRACT())
                .get_deposit_root() != data.depositRoot
        ) {
            revert("Invalid deposit root");
        }
        {
            uint256 wethBalance = IERC20(weth).balanceOf(address(this));
            uint256 unfinalizedStETH = withdrawalQueue.unfinalizedStETH();
            uint256 bufferedEther = ISteth(steth).getBufferedEther();
            if (bufferedEther < unfinalizedStETH)
                revert("Invalid withdrawal queue state");
            uint256 maxDepositsCount = Math.min(
                IStakingRouter(depositSecurityModule.STAKING_ROUTER())
                    .getStakingModuleMaxDepositsCount(
                        stakingModuleId,
                        wethBalance + bufferedEther - unfinalizedStETH
                    ),
                depositSecurityModule.getMaxDeposits()
            );
            amount = Math.min(wethBalance, 32 ether * maxDepositsCount);
        }
        if (amount == 0) revert("Invalid amount");
        return amount;
    }

    function deposit(bytes calldata data) external {
        Data memory data_ = abi.decode(data, (Data));
        IDepositSecurityModule(lidoLocator.depositSecurityModule())
            .depositBufferedEther(
                data_.blockNumber,
                data_.blockHash,
                data_.depositRoot,
                stakingModuleId,
                data_.nonce,
                data_.depositCalldata,
                data_.sortedGuardianSignatures
            );
    }
}

contract DVstETH is ERC20, DefaultAccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wsteth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    bytes32 private _reserved0;
    mapping(address user => IVault.WithdrawalRequest) public withdrawalRequests;
    bytes32[6] private _reserved1;
    uint256 public withdrawalDelay;
    IMutableStakingModule public stakingModule;

    constructor(
        address admin
    )
        ERC20("Decentralized Validator Token", "DVstETH")
        DefaultAccessControl(admin)
    {}

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "DVstETH: EXPIRED");
        _;
    }

    function setWithdrawalDelay(uint256 newWithdrawalDelay) external {
        _requireAdmin();
        require(newWithdrawalDelay != 0, "DVstETH: INVALID_WITHDRAWAL_DELAY");
        withdrawalDelay = newWithdrawalDelay;
    }

    function setStakingModule(IMutableStakingModule newStakingModule) external {
        _requireAdmin();
        stakingModule = newStakingModule;
    }

    function deposit(
        address to,
        uint256[] memory amounts,
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
        require(amounts.length == 1, "DVstETH: INVALID_AMOUNTS_LENGTH");
        uint256 amount = amounts[0];
        require(amount != 0);
        address this_ = address(this);
        if (msg.value == amount) {
            // eth deposit
            IWeth(weth).deposit{value: amount}();
        } else {
            // weth deposit
            require(msg.value == 0);
            IERC20(weth).safeTransferFrom(msg.sender, this_, amount);
        }
        uint256 totalAssets = IERC20(weth).balanceOf(this_) +
            IWSteth(wsteth).getStETHByWstETH(IERC20(wsteth).balanceOf(this_));
        lpAmount = Math.mulDiv(amount, totalSupply(), totalAssets);
        require(lpAmount >= minLpAmount, "DVstETH: INSUFFICIENT_LP_AMOUNT");
        _mint(to, lpAmount);
        emit IVault.Deposit(to, amounts, lpAmount, referralCode);
    }

    function submit(uint256 amount) public {
        _requireAtLeastOperator();
        _submit(amount);
    }

    function submitAndDeposit(bytes calldata data) public {
        uint256 amount = stakingModule.getDepositableEtherOrRevert(data);
        _submit(amount);
        stakingModule.deposit(data);
    }

    function _submit(uint256 amount) private {
        IWeth(weth).withdraw(amount);
        ISteth(steth).submit{value: amount}(address(0));
        IERC20(steth).safeIncreaseAllowance(address(wsteth), amount);
        IWSteth(wsteth).wrap(amount);
    }

    function registerWithdrawal(
        address to,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        uint256 deadline,
        uint256 requestDeadline,
        bool closePrevious
    )
        external
        nonReentrant
        checkDeadline(deadline)
        checkDeadline(requestDeadline)
    {
        require(minAmounts.length == 1, "DVstETH: INVALID_MIN_AMOUNTS_LENGTH");
        address sender = msg.sender;
        address this_ = address(this);
        uint256 previousWithdrawalRequest = withdrawalRequests[sender].lpAmount;
        if (previousWithdrawalRequest != 0) {
            require(
                closePrevious,
                "DVstETH: PREVIOUS_WITHDRAWAL_REQUEST_EXISTS"
            );
            _transfer(this_, sender, previousWithdrawalRequest);
            delete withdrawalRequests[sender];
        }

        lpAmount = Math.min(lpAmount, balanceOf(sender));
        require(lpAmount != 0, "DVstETH: INSUFFICIENT_LP_AMOUNT");
        _transfer(sender, this_, lpAmount);
        withdrawalRequests[sender] = IVault.WithdrawalRequest({
            to: to,
            lpAmount: lpAmount,
            tokensHash: bytes32(0),
            minAmounts: minAmounts,
            deadline: deadline,
            timestamp: block.timestamp
        });
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
            IVault.WithdrawalRequest memory request = withdrawalRequests[user];
            if (request.lpAmount == 0 || request.timestamp > latestTimestamp) {
                continue;
            }
            uint256 amount = Math.mulDiv(
                request.lpAmount,
                totalAssets_,
                totalSupply_
            );
            if (
                block.timestamp > request.deadline ||
                amount < request.minAmounts[0]
            ) {
                _transfer(this_, user, request.lpAmount);
                delete withdrawalRequests[user];
                continue;
            }
            if (amount > wstethBalance) {
                continue;
            }
            wstethBalance -= amount;
            totalAssets_ -= amount;
            _burn(this_, request.lpAmount);
            IERC20(wsteth).safeTransfer(request.to, amount);
            statuses[i] = true;
            delete withdrawalRequests[user];
        }
    }

    function recieve() external payable {
        require(msg.sender == weth, "DVstETH: INVALID_SENDER");
    }
}
