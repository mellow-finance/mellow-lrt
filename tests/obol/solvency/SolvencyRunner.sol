// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/obol/Deploy.s.sol";

contract SolvencyRunner is Test, DeployScript {
    enum Actions {
        DEPOSIT,
        REGISTER_WITHDRAWAL,
        PROCESS_WITHDRAWALS,
        CONVERT_AND_DEPOSIT,
        CONVERT,
        WITHDRAWAL_QUEUE_FULL,
        WITHDRAWAL_QUEUE_EMPTY
    }

    struct SolvencyTestParams {
        DeployInterfaces.DeployParameters deployParams;
        Actions[] actions;
    }

    function runSolvencyTest(
        SolvencyTestParams memory solvencyParams
    ) internal {
        solvencyParams.deployParams = commonContractsDeploy(
            solvencyParams.deployParams
        );
        vm.startPrank(solvencyParams.deployParams.deployer);
        (
            DeployInterfaces.DeployParameters memory deployParams,
            DeployInterfaces.DeploySetup memory setup
        ) = deploy(solvencyParams.deployParams);
        vm.stopPrank();

        /*
            1. check existing solvency tests for symbiotic
            2. modify them to make them fit current logic
            3. add different test for that
            4. fix validation scripts + remaining tests
        */
    }
}
