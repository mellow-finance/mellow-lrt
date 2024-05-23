
[<img width="200" alt="get in touch with Consensys Diligence" src="https://user-images.githubusercontent.com/2865694/56826101-91dcf380-685b-11e9-937c-af49c2510aa0.png">](https://consensys.io/diligence)<br/>
<sup>
[[  🌐  ](https://consensys.io/diligence)  [  📩  ](mailto:diligence@consensys.net)  [  🔥  ](https://consensys.io/diligence/tools/)]
</sup><br/><br/>



# Solidity Metrics for 'CLI'

## Table of contents

- [Scope](#t-scope)
    - [Source Units in Scope](#t-source-Units-in-Scope)
        - [Deployable Logic Contracts](#t-deployable-contracts)
    - [Out of Scope](#t-out-of-scope)
        - [Excluded Source Units](#t-out-of-scope-excluded-source-units)
        - [Duplicate Source Units](#t-out-of-scope-duplicate-source-units)
        - [Doppelganger Contracts](#t-out-of-scope-doppelganger-contracts)
- [Report Overview](#t-report)
    - [Risk Summary](#t-risk)
    - [Source Lines](#t-source-lines)
    - [Inline Documentation](#t-inline-documentation)
    - [Components](#t-components)
    - [Exposed Functions](#t-exposed-functions)
    - [StateVariables](#t-statevariables)
    - [Capabilities](#t-capabilities)
    - [Dependencies](#t-package-imports)
    - [Totals](#t-totals)

## <span id=t-scope>Scope</span>

This section lists files that are in scope for the metrics report. 

- **Project:** `'CLI'`
- **Included Files:** 
    - ``
- **Excluded Paths:** 
    - ``
- **File Limit:** `undefined`
    - **Exclude File list Limit:** `undefined`

- **Workspace Repository:** `unknown` (`undefined`@`undefined`)

### <span id=t-source-Units-in-Scope>Source Units in Scope</span>

Source Units Analyzed: **`22`**<br>
Source Units in Scope: **`22`** (**100%**)

| Type | File   | Logic Contracts | Interfaces | Lines | nLines | nSLOC | Comment Lines | Complex. Score | Capabilities |
| ---- | ------ | --------------- | ---------- | ----- | ------ | ----- | ------------- | -------------- | ------------ | 
| 📝 | ./src/Vault.sol | 1 | **** | 594 | 524 | 443 | 26 | 590 | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Payable Functions'>💰</abbr><abbr title='DelegateCall'>👥</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | ./src/VaultConfigurator.sol | 1 | **** | 652 | 562 | 365 | 95 | 487 | **<abbr title='Uses Assembly'>🖥</abbr>** |
| 🎨 | ./src/modules/DefaultModule.sol | 1 | **** | 18 | 18 | 13 | 1 | 12 | **** |
| 📝 | ./src/modules/erc20/ERC20SwapModule.sol | 1 | **** | 44 | 40 | 30 | 2 | 36 | **** |
| 📝 | ./src/modules/erc20/ERC20TvlModule.sol | 1 | **** | 21 | 19 | 15 | 2 | 28 | **** |
| 📝 | ./src/modules/erc20/ManagedTvlModule.sol | 1 | **** | 29 | 24 | 16 | 4 | 18 | **** |
| 📝 | ./src/modules/obol/StakingModule.sol | 1 | **** | 83 | 75 | 54 | 9 | 40 | **** |
| 📝 | ./src/modules/symbiotic/DefaultBondModule.sol | 1 | **** | 33 | 27 | 20 | 3 | 29 | **** |
| 📝 | ./src/modules/symbiotic/DefaultBondTvlModule.sol | 1 | **** | 36 | 31 | 23 | 4 | 38 | **** |
| 📝 | ./src/oracles/ChainlinkOracle.sol | 1 | **** | 102 | 87 | 65 | 11 | 64 | **** |
| 📝 | ./src/oracles/ConstantAggregatorV3.sol | 1 | **** | 35 | 23 | 17 | 1 | 12 | **** |
| 📝 | ./src/oracles/ManagedRatiosOracle.sol | 1 | **** | 48 | 41 | 30 | 5 | 36 | **<abbr title='Uses Hash-Functions'>🧮</abbr>** |
| 📝 | ./src/oracles/WStethRatiosAggregatorV3.sol | 1 | **** | 40 | 28 | 21 | 1 | 18 | **** |
| 📝 | ./src/strategies/DefaultBondStrategy.sol | 1 | **** | 120 | 120 | 95 | 10 | 89 | **** |
| 📝 | ./src/strategies/SimpleDVTStakingStrategy.sol | 1 | **** | 86 | 75 | 58 | 7 | 37 | **** |
| 📝 | ./src/utils/Collector.sol | 1 | **** | 253 | 222 | 204 | 1 | 235 | **<abbr title='TryCatch Blocks'>♻️</abbr>** |
| 📝 | ./src/utils/DefaultAccessControl.sol | 1 | **** | 64 | 64 | 44 | 7 | 44 | **<abbr title='Uses Hash-Functions'>🧮</abbr>** |
| 📝 | ./src/utils/DepositWrapper.sol | 1 | **** | 80 | 74 | 58 | 6 | 78 | **<abbr title='Payable Functions'>💰</abbr>** |
| 📝 | ./src/validators/AllowAllValidator.sol | 1 | **** | 9 | 9 | 5 | 2 | 5 | **** |
| 📝 | ./src/validators/DefaultBondValidator.sol | 1 | **** | 37 | 37 | 27 | 4 | 23 | **** |
| 📝 | ./src/validators/ERC20SwapValidator.sol | 1 | **** | 57 | 57 | 45 | 6 | 30 | **** |
| 📝 | ./src/validators/ManagedValidator.sol | 1 | **** | 176 | 140 | 96 | 20 | 99 | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Uses Hash-Functions'>🧮</abbr>** |
| 📝🎨 | **Totals** | **22** | **** | **2617**  | **2297** | **1744** | **227** | **2048** | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Payable Functions'>💰</abbr><abbr title='DelegateCall'>👥</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr><abbr title='TryCatch Blocks'>♻️</abbr>** |

<sub>
Legend: <a onclick="toggleVisibility('table-legend', this)">[➕]</a>
<div id="table-legend" style="display:none">

<ul>
<li> <b>Lines</b>: total lines of the source unit </li>
<li> <b>nLines</b>: normalized lines of the source unit (e.g. normalizes functions spanning multiple lines) </li>
<li> <b>nSLOC</b>: normalized source lines of code (only source-code lines; no comments, no blank lines) </li>
<li> <b>Comment Lines</b>: lines containing single or block comments </li>
<li> <b>Complexity Score</b>: a custom complexity score derived from code statements that are known to introduce code complexity (branches, loops, calls, external interfaces, ...) </li>
</ul>

</div>
</sub>


##### <span id=t-deployable-contracts>Deployable Logic Contracts</span>
Total: 20
* 📝 `Vault`
* 📝 `VaultConfigurator`
* 📝 `ERC20SwapModule`
* 📝 `ERC20TvlModule`
* 📝 `ManagedTvlModule`
* <a onclick="toggleVisibility('deployables', this)">[➕]</a>
<div id="deployables" style="display:none">
<ul>
<li> 📝 <code>StakingModule</code></li>
<li> 📝 <code>DefaultBondModule</code></li>
<li> 📝 <code>DefaultBondTvlModule</code></li>
<li> 📝 <code>ChainlinkOracle</code></li>
<li> 📝 <code>ConstantAggregatorV3</code></li>
<li> 📝 <code>ManagedRatiosOracle</code></li>
<li> 📝 <code>WStethRatiosAggregatorV3</code></li>
<li> 📝 <code>DefaultBondStrategy</code></li>
<li> 📝 <code>SimpleDVTStakingStrategy</code></li>
<li> 📝 <code>Collector</code></li>
<li> 📝 <code>DepositWrapper</code></li>
<li> 📝 <code>AllowAllValidator</code></li>
<li> 📝 <code>DefaultBondValidator</code></li>
<li> 📝 <code>ERC20SwapValidator</code></li>
<li> 📝 <code>ManagedValidator</code></li>
</ul>
</div>
            



#### <span id=t-out-of-scope>Out of Scope</span>

##### <span id=t-out-of-scope-excluded-source-units>Excluded Source Units</span>

Source Units Excluded: **`0`**

<a onclick="toggleVisibility('excluded-files', this)">[➕]</a>
<div id="excluded-files" style="display:none">
| File   |
| ------ |
| None |

</div>


##### <span id=t-out-of-scope-duplicate-source-units>Duplicate Source Units</span>

Duplicate Source Units Excluded: **`0`** 

<a onclick="toggleVisibility('duplicate-files', this)">[➕]</a>
<div id="duplicate-files" style="display:none">
| File   |
| ------ |
| None |

</div>

##### <span id=t-out-of-scope-doppelganger-contracts>Doppelganger Contracts</span>

Doppelganger Contracts: **`0`** 

<a onclick="toggleVisibility('doppelganger-contracts', this)">[➕]</a>
<div id="doppelganger-contracts" style="display:none">
| File   | Contract | Doppelganger | 
| ------ | -------- | ------------ |


</div>


## <span id=t-report>Report</span>

### Overview

The analysis finished with **`0`** errors and **`0`** duplicate files.





#### <span id=t-risk>Risk</span>

<div class="wrapper" style="max-width: 512px; margin: auto">
			<canvas id="chart-risk-summary"></canvas>
</div>

#### <span id=t-source-lines>Source Lines (sloc vs. nsloc)</span>

<div class="wrapper" style="max-width: 512px; margin: auto">
    <canvas id="chart-nsloc-total"></canvas>
</div>

#### <span id=t-inline-documentation>Inline Documentation</span>

- **Comment-to-Source Ratio:** On average there are`9.09` code lines per comment (lower=better).
- **ToDo's:** `0` 

#### <span id=t-components>Components</span>

| 📝Contracts   | 📚Libraries | 🔍Interfaces | 🎨Abstract |
| ------------- | ----------- | ------------ | ---------- |
| 21 | 0  | 0  | 1 |

#### <span id=t-exposed-functions>Exposed Functions</span>

This section lists functions that are explicitly declared public or payable. Please note that getter methods for public stateVars are not included.  

| 🌐Public   | 💰Payable |
| ---------- | --------- |
| 175 | 3  | 

| External   | Internal | Private | Pure | View |
| ---------- | -------- | ------- | ---- | ---- |
| 162 | 138  | 14 | 4 | 68 |

#### <span id=t-statevariables>StateVariables</span>

| Total      | 🌐Public  |
| ---------- | --------- |
| 78  | 49 |

#### <span id=t-capabilities>Capabilities</span>

| Solidity Versions observed | 🧪 Experimental Features | 💰 Can Receive Funds | 🖥 Uses Assembly | 💣 Has Destroyable Contracts | 
| -------------------------- | ------------------------ | -------------------- | ---------------- | ---------------------------- |
| `0.8.25` |  | `yes` | `yes` <br/>(5 asm blocks) | **** | 

| 📤 Transfers ETH | ⚡ Low-Level Calls | 👥 DelegateCall | 🧮 Uses Hash Functions | 🔖 ECRecover | 🌀 New/Create/Create2 |
| ---------------- | ----------------- | --------------- | ---------------------- | ------------ | --------------------- |
| **** | **** | `yes` | `yes` | **** | `yes`<br>→ `NewContract:VaultConfigurator` | 

| ♻️ TryCatch | Σ Unchecked |
| ---------- | ----------- |
| `yes` | **** |

#### <span id=t-package-imports>Dependencies / External Imports</span>

| Dependency / Import Path | Count  | 
| ------------------------ | ------ |
| @openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol | 1 |
| @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol | 1 |
| @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol | 1 |
| @openzeppelin/contracts/utils/Strings.sol | 1 |

#### <span id=t-totals>Totals</span>

##### Summary

<div class="wrapper" style="max-width: 90%; margin: auto">
    <canvas id="chart-num-bar"></canvas>
</div>

##### AST Node Statistics

###### Function Calls

<div class="wrapper" style="max-width: 90%; margin: auto">
    <canvas id="chart-num-bar-ast-funccalls"></canvas>
</div>

###### Assembly Calls

<div class="wrapper" style="max-width: 90%; margin: auto">
    <canvas id="chart-num-bar-ast-asmcalls"></canvas>
</div>

###### AST Total

<div class="wrapper" style="max-width: 90%; margin: auto">
    <canvas id="chart-num-bar-ast"></canvas>
</div>

##### Inheritance Graph

<a onclick="toggleVisibility('surya-inherit', this)">[➕]</a>
<div id="surya-inherit" style="display:none">
<div class="wrapper" style="max-width: 512px; margin: auto">
    <div id="surya-inheritance" style="text-align: center;"></div> 
</div>
</div>

##### CallGraph

<a onclick="toggleVisibility('surya-call', this)">[➕]</a>
<div id="surya-call" style="display:none">
<div class="wrapper" style="max-width: 512px; margin: auto">
    <div id="surya-callgraph" style="text-align: center;"></div>
</div>
</div>

###### Contract Summary

<a onclick="toggleVisibility('surya-mdreport', this)">[➕]</a>
<div id="surya-mdreport" style="display:none">
 Sūrya's Description Report

 Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ./src/Vault.sol | [object Promise] |
| ./src/VaultConfigurator.sol | [object Promise] |
| ./src/modules/DefaultModule.sol | [object Promise] |
| ./src/modules/erc20/ERC20SwapModule.sol | [object Promise] |
| ./src/modules/erc20/ERC20TvlModule.sol | [object Promise] |
| ./src/modules/erc20/ManagedTvlModule.sol | [object Promise] |
| ./src/modules/obol/StakingModule.sol | [object Promise] |
| ./src/modules/symbiotic/DefaultBondModule.sol | [object Promise] |
| ./src/modules/symbiotic/DefaultBondTvlModule.sol | [object Promise] |
| ./src/oracles/ChainlinkOracle.sol | [object Promise] |
| ./src/oracles/ConstantAggregatorV3.sol | [object Promise] |
| ./src/oracles/ManagedRatiosOracle.sol | [object Promise] |
| ./src/oracles/WStethRatiosAggregatorV3.sol | [object Promise] |
| ./src/strategies/DefaultBondStrategy.sol | [object Promise] |
| ./src/strategies/SimpleDVTStakingStrategy.sol | [object Promise] |
| ./src/utils/Collector.sol | [object Promise] |
| ./src/utils/DefaultAccessControl.sol | [object Promise] |
| ./src/utils/DepositWrapper.sol | [object Promise] |
| ./src/validators/AllowAllValidator.sol | [object Promise] |
| ./src/validators/DefaultBondValidator.sol | [object Promise] |
| ./src/validators/ERC20SwapValidator.sol | [object Promise] |
| ./src/validators/ManagedValidator.sol | [object Promise] |


 Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **Vault** | Implementation | IVault, ERC20, DefaultAccessControl, ReentrancyGuard |||
| └ | withdrawalRequest | External ❗️ |   |NO❗️ |
| └ | pendingWithdrawersCount | External ❗️ |   |NO❗️ |
| └ | pendingWithdrawers | External ❗️ |   |NO❗️ |
| └ | pendingWithdrawers | External ❗️ |   |NO❗️ |
| └ | underlyingTokens | External ❗️ |   |NO❗️ |
| └ | tvlModules | External ❗️ |   |NO❗️ |
| └ | _calculateTvl | Private 🔐 |   | |
| └ | underlyingTvl | Public ❗️ |   |NO❗️ |
| └ | baseTvl | Public ❗️ |   |NO❗️ |
| └ | _tvls | Private 🔐 |   | |
| └ | <Constructor> | Public ❗️ | 🛑  | ERC20 DefaultAccessControl |
| └ | addToken | External ❗️ | 🛑  | nonReentrant |
| └ | removeToken | External ❗️ | 🛑  | nonReentrant |
| └ | addTvlModule | External ❗️ | 🛑  | nonReentrant |
| └ | removeTvlModule | External ❗️ | 🛑  | nonReentrant |
| └ | externalCall | External ❗️ | 🛑  | nonReentrant |
| └ | delegateCall | External ❗️ | 🛑  |NO❗️ |
| └ | deposit | External ❗️ | 🛑  | nonReentrant checkDeadline |
| └ | _processLpAmount | Private 🔐 | 🛑  | |
| └ | emergencyWithdraw | External ❗️ | 🛑  | nonReentrant checkDeadline |
| └ | cancelWithdrawalRequest | External ❗️ | 🛑  | nonReentrant |
| └ | _cancelWithdrawalRequest | Private 🔐 | 🛑  | |
| └ | registerWithdrawal | External ❗️ | 🛑  | nonReentrant checkDeadline checkDeadline |
| └ | analyzeRequest | Public ❗️ |   |NO❗️ |
| └ | calculateStack | Public ❗️ |   |NO❗️ |
| └ | processWithdrawals | External ❗️ | 🛑  | nonReentrant |
| └ | <Receive Ether> | External ❗️ |  💵 |NO❗️ |
| └ | _update | Internal 🔒 | 🛑  | |
||||||
| **VaultConfigurator** | Implementation | IVaultConfigurator, ReentrancyGuard |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | _stage | Private 🔐 | 🛑  | |
| └ | _commit | Private 🔐 | 🛑  | |
| └ | _rollback | Private 🔐 | 🛑  | |
| └ | isDelegateModuleApproved | External ❗️ |   |NO❗️ |
| └ | isDepositLocked | External ❗️ |   |NO❗️ |
| └ | areTransfersLocked | External ❗️ |   |NO❗️ |
| └ | maximalTotalSupply | External ❗️ |   |NO❗️ |
| └ | depositCallback | External ❗️ |   |NO❗️ |
| └ | withdrawalCallback | External ❗️ |   |NO❗️ |
| └ | withdrawalFeeD9 | External ❗️ |   |NO❗️ |
| └ | stageDelegateModuleApproval | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitDelegateModuleApproval | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedDelegateModuleApproval | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | revokeDelegateModuleApproval | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stageDepositsLock | External ❗️ | 🛑  | atLeastOperator nonReentrant |
| └ | commitDepositsLock | External ❗️ | 🛑  | atLeastOperator nonReentrant |
| └ | rollbackStagedDepositsLock | External ❗️ | 🛑  | atLeastOperator nonReentrant |
| └ | revokeDepositsLock | External ❗️ | 🛑  | atLeastOperator nonReentrant |
| └ | stageTransfersLock | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitTransfersLock | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedTransfersLock | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stageMaximalTotalSupply | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitMaximalTotalSupply | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedMaximalTotalSupply | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stageDepositCallback | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitDepositCallback | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedDepositCallback | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stageWithdrawalCallback | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitWithdrawalCallback | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedWithdrawalCallback | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stageWithdrawalFeeD9 | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitWithdrawalFeeD9 | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedWithdrawalFeeD9 | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | baseDelay | External ❗️ |   |NO❗️ |
| └ | stageBaseDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitBaseDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedBaseDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | depositCallbackDelay | External ❗️ |   |NO❗️ |
| └ | stageDepositCallbackDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitDepositCallbackDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedDepositCallbackDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | withdrawalCallbackDelay | External ❗️ |   |NO❗️ |
| └ | stageWithdrawalCallbackDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitWithdrawalCallbackDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedWithdrawalCallbackDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | withdrawalFeeD9Delay | External ❗️ |   |NO❗️ |
| └ | stageWithdrawalFeeD9Delay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitWithdrawalFeeD9Delay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedWithdrawalFeeD9Delay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | isDepositLockedDelay | External ❗️ |   |NO❗️ |
| └ | stageDepositsLockedDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitDepositsLockedDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedDepositsLockedDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | areTransfersLockedDelay | External ❗️ |   |NO❗️ |
| └ | stageTransfersLockedDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitTransfersLockedDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedTransfersLockedDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | delegateModuleApprovalDelay | External ❗️ |   |NO❗️ |
| └ | stageDelegateModuleApprovalDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitDelegateModuleApprovalDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedDelegateModuleApprovalDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | maximalTotalSupplyDelay | External ❗️ |   |NO❗️ |
| └ | stageMaximalTotalSupplyDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitMaximalTotalSupplyDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedMaximalTotalSupplyDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | ratiosOracle | External ❗️ |   |NO❗️ |
| └ | priceOracle | External ❗️ |   |NO❗️ |
| └ | validator | External ❗️ |   |NO❗️ |
| └ | stageRatiosOracle | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitRatiosOracle | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedRatiosOracle | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stagePriceOracle | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitPriceOracle | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedPriceOracle | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stageValidator | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitValidator | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedValidator | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | priceOracleDelay | External ❗️ |   |NO❗️ |
| └ | ratiosOracleDelay | External ❗️ |   |NO❗️ |
| └ | validatorDelay | External ❗️ |   |NO❗️ |
| └ | stageValidatorDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitValidatorDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedValidatorDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stagePriceOracleDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitPriceOracleDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedPriceOracleDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | stageRatiosOracleDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitRatiosOracleDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedRatiosOracleDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | emergencyWithdrawalDelay | External ❗️ |   |NO❗️ |
| └ | stageEmergencyWithdrawalDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | commitEmergencyWithdrawalDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
| └ | rollbackStagedEmergencyWithdrawalDelay | External ❗️ | 🛑  | onlyAdmin nonReentrant |
||||||
| **DefaultModule** | Implementation | IDefaultModule |||
||||||
| **ERC20SwapModule** | Implementation | IERC20SwapModule, DefaultModule |||
| └ | swap | External ❗️ | 🛑  | onlyDelegateCall |
||||||
| **ERC20TvlModule** | Implementation | IERC20TvlModule, DefaultModule |||
| └ | tvl | External ❗️ |   | noDelegateCall |
||||||
| **ManagedTvlModule** | Implementation | IManagedTvlModule, DefaultModule |||
| └ | setParams | External ❗️ | 🛑  | noDelegateCall |
| └ | tvl | External ❗️ |   | noDelegateCall |
||||||
| **StakingModule** | Implementation | IStakingModule, DefaultModule |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | convert | External ❗️ | 🛑  | onlyDelegateCall |
| └ | convertAndDeposit | External ❗️ | 🛑  | onlyDelegateCall |
| └ | _wethToWSteth | Private 🔐 | 🛑  | |
||||||
| **DefaultBondModule** | Implementation | IDefaultBondModule, DefaultModule |||
| └ | deposit | External ❗️ | 🛑  | onlyDelegateCall |
| └ | withdraw | External ❗️ | 🛑  | onlyDelegateCall |
||||||
| **DefaultBondTvlModule** | Implementation | IDefaultBondTvlModule, DefaultModule |||
| └ | setParams | External ❗️ | 🛑  | noDelegateCall |
| └ | tvl | External ❗️ |   | noDelegateCall |
||||||
| **ChainlinkOracle** | Implementation | IChainlinkOracle |||
| └ | aggregatorsData | External ❗️ |   |NO❗️ |
| └ | setBaseToken | External ❗️ | 🛑  |NO❗️ |
| └ | setChainlinkOracles | External ❗️ | 🛑  |NO❗️ |
| └ | _validateAndGetPrice | Private 🔐 |   | |
| └ | getPrice | Public ❗️ |   |NO❗️ |
| └ | priceX96 | External ❗️ |   |NO❗️ |
||||||
| **ConstantAggregatorV3** | Implementation | IAggregatorV3 |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | getRoundData | External ❗️ |   |NO❗️ |
| └ | latestRoundData | Public ❗️ |   |NO❗️ |
||||||
| **ManagedRatiosOracle** | Implementation | IManagedRatiosOracle |||
| └ | updateRatios | External ❗️ | 🛑  |NO❗️ |
| └ | getTargetRatiosX96 | External ❗️ |   |NO❗️ |
||||||
| **WStethRatiosAggregatorV3** | Implementation | IAggregatorV3 |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | getAnswer | Public ❗️ |   |NO❗️ |
| └ | getRoundData | External ❗️ |   |NO❗️ |
| └ | latestRoundData | Public ❗️ |   |NO❗️ |
||||||
| **DefaultBondStrategy** | Implementation | IDefaultBondStrategy, DefaultAccessControl |||
| └ | <Constructor> | Public ❗️ | 🛑  | DefaultAccessControl |
| └ | setData | External ❗️ | 🛑  |NO❗️ |
| └ | _deposit | Private 🔐 | 🛑  | |
| └ | depositCallback | External ❗️ | 🛑  |NO❗️ |
| └ | processAll | External ❗️ | 🛑  |NO❗️ |
| └ | processWithdrawals | External ❗️ | 🛑  |NO❗️ |
| └ | _processWithdrawals | Private 🔐 | 🛑  | |
||||||
| **SimpleDVTStakingStrategy** | Implementation | ISimpleDVTStakingStrategy, DefaultAccessControl |||
| └ | <Constructor> | Public ❗️ | 🛑  | DefaultAccessControl |
| └ | setMaxAllowedRemainder | External ❗️ | 🛑  |NO❗️ |
| └ | convertAndDeposit | External ❗️ | 🛑  |NO❗️ |
| └ | processWithdrawals | External ❗️ | 🛑  |NO❗️ |
||||||
| **Collector** | Implementation |  |||
| └ | collect | Public ❗️ |   |NO❗️ |
| └ | fetchWithdrawalAmounts | External ❗️ |   |NO❗️ |
| └ | fetchDepositWrapperParams | External ❗️ |   |NO❗️ |
| └ | fetchDepositAmounts | External ❗️ |   |NO❗️ |
| └ | test | External ❗️ |   |NO❗️ |
||||||
| **DefaultAccessControl** | Implementation | IDefaultAccessControl, AccessControlEnumerable |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | isAdmin | Public ❗️ |   |NO❗️ |
| └ | isOperator | Public ❗️ |   |NO❗️ |
| └ | requireAdmin | External ❗️ |   |NO❗️ |
| └ | requireAtLeastOperator | External ❗️ |   |NO❗️ |
| └ | _requireAdmin | Internal 🔒 |   | |
| └ | _requireAtLeastOperator | Internal 🔒 |   | |
| └ | _requireAdmin | Internal 🔒 |   | |
| └ | _requireAtLeastOperator | Internal 🔒 |   | |
||||||
| **DepositWrapper** | Implementation | IDepositWrapper |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | _wethToWsteth | Private 🔐 | 🛑  | |
| └ | _ethToSteth | Private 🔐 | 🛑  | |
| └ | _stethToWsteth | Private 🔐 | 🛑  | |
| └ | deposit | External ❗️ |  💵 |NO❗️ |
| └ | <Receive Ether> | External ❗️ |  💵 |NO❗️ |
||||||
| **AllowAllValidator** | Implementation | IAllowAllValidator |||
| └ | validate | External ❗️ |   |NO❗️ |
||||||
| **DefaultBondValidator** | Implementation | IDefaultBondValidator, DefaultAccessControl |||
| └ | <Constructor> | Public ❗️ | 🛑  | DefaultAccessControl |
| └ | setSupportedBond | External ❗️ | 🛑  |NO❗️ |
| └ | validate | External ❗️ |   |NO❗️ |
||||||
| **ERC20SwapValidator** | Implementation | IERC20SwapValidator, DefaultAccessControl |||
| └ | <Constructor> | Public ❗️ | 🛑  | DefaultAccessControl |
| └ | setSupportedRouter | External ❗️ | 🛑  |NO❗️ |
| └ | setSupportedToken | External ❗️ | 🛑  |NO❗️ |
| └ | validate | External ❗️ |   |NO❗️ |
||||||
| **ManagedValidator** | Implementation | IManagedValidator |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | _storage | Internal 🔒 |   | |
| └ | hasPermission | Public ❗️ |   |NO❗️ |
| └ | requirePermission | Public ❗️ |   |NO❗️ |
| └ | grantPublicRole | External ❗️ | 🛑  | authorized |
| └ | revokePublicRole | External ❗️ | 🛑  | authorized |
| └ | grantRole | External ❗️ | 🛑  | authorized |
| └ | revokeRole | External ❗️ | 🛑  | authorized |
| └ | setCustomValidator | External ❗️ | 🛑  | authorized |
| └ | grantContractRole | External ❗️ | 🛑  | authorized |
| └ | revokeContractRole | External ❗️ | 🛑  | authorized |
| └ | grantContractSignatureRole | External ❗️ | 🛑  | authorized |
| └ | revokeContractSignatureRole | External ❗️ | 🛑  | authorized |
| └ | customValidator | External ❗️ |   |NO❗️ |
| └ | userRoles | External ❗️ |   |NO❗️ |
| └ | publicRoles | External ❗️ |   |NO❗️ |
| └ | allowAllSignaturesRoles | External ❗️ |   |NO❗️ |
| └ | allowSignatureRoles | External ❗️ |   |NO❗️ |
| └ | validate | External ❗️ |   |NO❗️ |


 Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
 

</div>
____
<sub>
Thinking about smart contract security? We can provide training, ongoing advice, and smart contract auditing. [Contact us](https://consensys.io/diligence/contact/).
</sub>


