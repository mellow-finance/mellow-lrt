
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

Source Units Analyzed: **`27`**<br>
Source Units in Scope: **`27`** (**100%**)

| Type | File   | Logic Contracts | Interfaces | Lines | nLines | nSLOC | Comment Lines | Complex. Score | Capabilities |
| ---- | ------ | --------------- | ---------- | ----- | ------ | ----- | ------------- | -------------- | ------------ | 
| 📝 | ./src/Vault.sol | 1 | **** | 610 | 537 | 454 | 27 | 593 | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Payable Functions'>💰</abbr><abbr title='DelegateCall'>👥</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | ./src/VaultConfigurator.sol | 1 | **** | 652 | 562 | 365 | 95 | 487 | **<abbr title='Uses Assembly'>🖥</abbr>** |
| 🎨 | ./src/modules/DefaultModule.sol | 1 | **** | 18 | 18 | 13 | 1 | 12 | **** |
| 📝 | ./src/modules/erc20/ERC20SwapModule.sol | 1 | **** | 44 | 40 | 30 | 2 | 36 | **** |
| 📝 | ./src/modules/erc20/ERC20TvlModule.sol | 1 | **** | 21 | 19 | 15 | 2 | 28 | **** |
| 📝 | ./src/modules/erc20/ManagedTvlModule.sol | 1 | **** | 32 | 27 | 19 | 4 | 27 | **** |
| 📝 | ./src/modules/obol/StakingModule.sol | 1 | **** | 103 | 96 | 77 | 9 | 55 | **** |
| 📝 | ./src/modules/symbiotic/DefaultBondModule.sol | 1 | **** | 38 | 32 | 25 | 3 | 35 | **** |
| 📝 | ./src/modules/symbiotic/DefaultBondTvlModule.sol | 1 | **** | 39 | 34 | 26 | 4 | 49 | **** |
| 📝 | ./src/oracles/ChainlinkOracle.sol | 1 | **** | 102 | 87 | 65 | 10 | 67 | **** |
| 📝 | ./src/oracles/ConstantAggregatorV3.sol | 1 | **** | 22 | 17 | 12 | 1 | 7 | **** |
| 📝 | ./src/oracles/ManagedRatiosOracle.sol | 1 | **** | 48 | 41 | 30 | 5 | 36 | **<abbr title='Uses Hash-Functions'>🧮</abbr>** |
| 📝 | ./src/oracles/WStethRatiosAggregatorV3.sol | 1 | **** | 27 | 22 | 16 | 1 | 13 | **** |
| 📝 | ./src/security/AdminProxy.sol | 1 | **** | 164 | 152 | 112 | 20 | 81 | **** |
| 📝 | ./src/security/DefaultProxyImplementation.sol | 1 | **** | 17 | 17 | 12 | 1 | 5 | **** |
| 📝 | ./src/security/Initializer.sol | 1 | **** | 40 | 36 | 25 | 4 | 76 | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | ./src/strategies/DefaultBondStrategy.sol | 1 | **** | 122 | 122 | 97 | 10 | 92 | **** |
| 📝 | ./src/strategies/SimpleDVTStakingStrategy.sol | 1 | **** | 84 | 74 | 57 | 7 | 38 | **** |
| 📝🔍 | ./src/utils/DVstETH.sol | 1 | 1 | 365 | 315 | 249 | 40 | 272 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Uses Hash-Functions'>🧮</abbr>** |
| 📝 | ./src/utils/DVstETHOperator.sol | 1 | **** | 20 | 20 | 16 | 1 | 15 | **** |
| 📝 | ./src/utils/DefaultAccessControl.sol | 1 | **** | 64 | 64 | 44 | 7 | 44 | **<abbr title='Uses Hash-Functions'>🧮</abbr>** |
| 📝 | ./src/utils/DepositWrapper.sol | 1 | **** | 87 | 80 | 64 | 6 | 78 | **<abbr title='Payable Functions'>💰</abbr>** |
| 📝 | ./src/utils/RestrictingKeeper.sol | 1 | **** | 21 | 19 | 15 | 1 | 15 | **** |
| 📝 | ./src/validators/AllowAllValidator.sol | 1 | **** | 9 | 9 | 5 | 2 | 5 | **** |
| 📝 | ./src/validators/DefaultBondValidator.sol | 1 | **** | 37 | 37 | 27 | 4 | 23 | **** |
| 📝 | ./src/validators/ERC20SwapValidator.sol | 1 | **** | 57 | 57 | 45 | 6 | 30 | **** |
| 📝 | ./src/validators/ManagedValidator.sol | 1 | **** | 176 | 140 | 96 | 20 | 99 | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Uses Hash-Functions'>🧮</abbr>** |
| 📝🔍🎨 | **Totals** | **27** | **1** | **3019**  | **2674** | **2011** | **293** | **2318** | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Payable Functions'>💰</abbr><abbr title='DelegateCall'>👥</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |

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
Total: 25
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
<li> 📝 <code>AdminProxy</code></li>
<li> 📝 <code>DefaultProxyImplementation</code></li>
<li> 📝 <code>Initializer</code></li>
<li> 📝 <code>DefaultBondStrategy</code></li>
<li> 📝 <code>SimpleDVTStakingStrategy</code></li>
<li> 📝 <code>DVstETH</code></li>
<li> 📝 <code>DVstETHOpeartor</code></li>
<li> 📝 <code>DepositWrapper</code></li>
<li> 📝 <code>RestrictingKeeper</code></li>
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

- **Comment-to-Source Ratio:** On average there are`8.04` code lines per comment (lower=better).
- **ToDo's:** `1` 

#### <span id=t-components>Components</span>

| 📝Contracts   | 📚Libraries | 🔍Interfaces | 🎨Abstract |
| ------------- | ----------- | ------------ | ---------- |
| 26 | 0  | 1  | 1 |

#### <span id=t-exposed-functions>Exposed Functions</span>

This section lists functions that are explicitly declared public or payable. Please note that getter methods for public stateVars are not included.  

| 🌐Public   | 💰Payable |
| ---------- | --------- |
| 203 | 5  | 

| External   | Internal | Private | Pure | View |
| ---------- | -------- | ------- | ---- | ---- |
| 189 | 168  | 16 | 4 | 73 |

#### <span id=t-statevariables>StateVariables</span>

| Total      | 🌐Public  |
| ---------- | --------- |
| 95  | 58 |

#### <span id=t-capabilities>Capabilities</span>

| Solidity Versions observed | 🧪 Experimental Features | 💰 Can Receive Funds | 🖥 Uses Assembly | 💣 Has Destroyable Contracts | 
| -------------------------- | ------------------------ | -------------------- | ---------------- | ---------------------------- |
| `0.8.25` |  | `yes` | `yes` <br/>(6 asm blocks) | **** | 

| 📤 Transfers ETH | ⚡ Low-Level Calls | 👥 DelegateCall | 🧮 Uses Hash Functions | 🔖 ECRecover | 🌀 New/Create/Create2 |
| ---------------- | ----------------- | --------------- | ---------------------- | ------------ | --------------------- |
| **** | **** | `yes` | `yes` | **** | `yes`<br>→ `NewContract:VaultConfigurator` | 

| ♻️ TryCatch | Σ Unchecked |
| ---------- | ----------- |
| **** | **** |

#### <span id=t-package-imports>Dependencies / External Imports</span>

| Dependency / Import Path | Count  | 
| ------------------------ | ------ |
| @openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol | 1 |
| @openzeppelin/contracts/token/ERC20/ERC20.sol | 1 |

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
| ./src/Vault.sol | 4cfbd713422393a7cb2921a9a9cada2ad3a3be1c |
| ./src/VaultConfigurator.sol | 0ff6528b2f59a6cbd46910a793cee3ad2da57a6d |
| ./src/modules/DefaultModule.sol | 56d9e6d3bd4bf7470d6dc2dbf4804c312baf63a7 |
| ./src/modules/erc20/ERC20SwapModule.sol | c455691b0d589940249dfe90269411cab949a6fe |
| ./src/modules/erc20/ERC20TvlModule.sol | 10897f6145ae43623fdfc9bed770bdddb5d4f629 |
| ./src/modules/erc20/ManagedTvlModule.sol | 0898c0de861984ddf428a1d896ef06c92f57c0fd |
| ./src/modules/obol/StakingModule.sol | e9b9bad7990f1dfbc8d73dd4428756c217848e36 |
| ./src/modules/symbiotic/DefaultBondModule.sol | 02708b67456e0c40d7b76366c0c8b869ddce7a0f |
| ./src/modules/symbiotic/DefaultBondTvlModule.sol | f9be79ffac08a7964d19f3760b82bf55ac30912f |
| ./src/oracles/ChainlinkOracle.sol | 07672d781a48520e2426c2315d03cc02f54749e8 |
| ./src/oracles/ConstantAggregatorV3.sol | f3c3b9ade949047a6323ecf4402bf389e59ae694 |
| ./src/oracles/ManagedRatiosOracle.sol | d6fcae6f8745913383c6d7b30e771fb8f7ff4d61 |
| ./src/oracles/WStethRatiosAggregatorV3.sol | aadc6c52582c58f22039c292103fcb9a108671a6 |
| ./src/security/AdminProxy.sol | fac22b7dab8653de620729cf633be77f87c896f7 |
| ./src/security/DefaultProxyImplementation.sol | 20f1d13fc0f4186d6841d7b4d0ec8fce6da0e717 |
| ./src/security/Initializer.sol | 61fb77d74e6e0bde99a2694231aa4fe49748dded |
| ./src/strategies/DefaultBondStrategy.sol | fdaf8fe32427abe95e7babe0a4fc5ce20144c3c3 |
| ./src/strategies/SimpleDVTStakingStrategy.sol | 302c20ef2cef3e81fb0930babda578906b6cc1cc |
| ./src/utils/DVstETH.sol | b082927a236af85ffdcfab9caeb077c39e25cc08 |
| ./src/utils/DVstETHOperator.sol | c2ae785aa59753fcf47a135ab44cbe4cdd0a3636 |
| ./src/utils/DefaultAccessControl.sol | 32beaf7684c5aa4ffd8400a10ed0e4e0170fec54 |
| ./src/utils/DepositWrapper.sol | 3a9673fa1d9c65b4a661546d53dbb10ad97cd5b3 |
| ./src/utils/RestrictingKeeper.sol | 2a23e8943ba199184c8464022e2884c2ea1396c1 |
| ./src/validators/AllowAllValidator.sol | 384282365bef60be2d1115d292fc68ceb090ba43 |
| ./src/validators/DefaultBondValidator.sol | fdfba0f0ac3d6a09e5b2a80218bc8ab480476b86 |
| ./src/validators/ERC20SwapValidator.sol | 5297db69f327241e375c71c69e03ebf855daddd9 |
| ./src/validators/ManagedValidator.sol | 8f3aba4367e043647cce2e5e547605d87d4f321a |


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
| └ | isUnderlyingToken | External ❗️ |   |NO❗️ |
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
| └ | latestRoundData | Public ❗️ |   |NO❗️ |
||||||
| **ManagedRatiosOracle** | Implementation | IManagedRatiosOracle |||
| └ | updateRatios | External ❗️ | 🛑  |NO❗️ |
| └ | getTargetRatiosX96 | External ❗️ |   |NO❗️ |
||||||
| **WStethRatiosAggregatorV3** | Implementation | IAggregatorV3 |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | getAnswer | Public ❗️ |   |NO❗️ |
| └ | latestRoundData | Public ❗️ |   |NO❗️ |
||||||
| **AdminProxy** | Implementation | IAdminProxy |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | baseImplementation | External ❗️ |   |NO❗️ |
| └ | proposedBaseImplementation | External ❗️ |   |NO❗️ |
| └ | proposalAt | External ❗️ |   |NO❗️ |
| └ | proposalsCount | External ❗️ |   |NO❗️ |
| └ | upgradeEmergencyOperator | External ❗️ | 🛑  | onlyAcceptor |
| └ | upgradeProposer | External ❗️ | 🛑  | onlyAcceptor |
| └ | upgradeAcceptor | External ❗️ | 🛑  | onlyAcceptor |
| └ | proposeBaseImplementation | External ❗️ | 🛑  | requireProposerOrAcceptor |
| └ | propose | External ❗️ | 🛑  | requireProposerOrAcceptor |
| └ | acceptBaseImplementation | External ❗️ | 🛑  | onlyAcceptor |
| └ | acceptProposal | External ❗️ | 🛑  | onlyAcceptor |
| └ | rejectAllProposals | External ❗️ | 🛑  | onlyAcceptor |
| └ | resetToBaseImplementation | External ❗️ | 🛑  | onlyEmergencyOperator |
||||||
| **DefaultProxyImplementation** | Implementation | ERC20 |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC20 |
| └ | _update | Internal 🔒 |   | |
||||||
| **Initializer** | Implementation | ERC20, DefaultAccessControl, ReentrancyGuard |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC20 DefaultAccessControl |
| └ | initialize | External ❗️ | 🛑  |NO❗️ |
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
| **IMutableStakingModule** | Interface |  |||
| └ | getAmountForStake | External ❗️ |   |NO❗️ |
||||||
| **DVstETH** | Implementation | ERC20, DefaultAccessControl, ReentrancyGuard |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC20 DefaultAccessControl |
| └ | setWithdrawalDelay | External ❗️ | 🛑  |NO❗️ |
| └ | setStakingModule | External ❗️ | 🛑  |NO❗️ |
| └ | setTotalSupplyLimit | External ❗️ | 🛑  |NO❗️ |
| └ | setEmergencyWithdrawalDelay | External ❗️ | 🛑  |NO❗️ |
| └ | deposit | Public ❗️ |  💵 | nonReentrant checkDeadline |
| └ | submit | External ❗️ | 🛑  |NO❗️ |
| └ | submit | External ❗️ | 🛑  |NO❗️ |
| └ | _submit | Private 🔐 | 🛑  | |
| └ | registerWithdrawal | External ❗️ | 🛑  | nonReentrant checkDeadline checkDeadline |
| └ | cancelWithdrawalRequest | External ❗️ | 🛑  | nonReentrant |
| └ | _cancelWithdrawalRequest | Private 🔐 | 🛑  | |
| └ | emergencyWithdraw | External ❗️ | 🛑  | nonReentrant checkDeadline |
| └ | processWithdrawals | External ❗️ | 🛑  | nonReentrant |
| └ | <Receive Ether> | External ❗️ |  💵 |NO❗️ |
| └ | withdrawalRequest | External ❗️ |   |NO❗️ |
| └ | pendingWithdrawersCount | External ❗️ |   |NO❗️ |
| └ | pendingWithdrawers | External ❗️ |   |NO❗️ |
| └ | pendingWithdrawers | External ❗️ |   |NO❗️ |
| └ | calculateStack | Public ❗️ |   |NO❗️ |
||||||
| **DVstETHOpeartor** | Implementation |  |||
| └ | process | External ❗️ | 🛑  |NO❗️ |
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
| └ | _ethToWsteth | Private 🔐 | 🛑  | |
| └ | _stethToWsteth | Private 🔐 | 🛑  | |
| └ | deposit | External ❗️ |  💵 |NO❗️ |
| └ | <Receive Ether> | External ❗️ |  💵 |NO❗️ |
||||||
| **RestrictingKeeper** | Implementation | DefaultAccessControl |||
| └ | <Constructor> | Public ❗️ | 🛑  | DefaultAccessControl |
| └ | processConfigurators | External ❗️ | 🛑  |NO❗️ |
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


