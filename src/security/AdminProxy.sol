// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

contract AdminProxy {
    address proposer;
    address acceptor;

    function proposeImplementation(address _implementation) public {
        require(
            msg.sender == proposer,
            "AdminProxy: only proposer can propose"
        );
        // propose implementation
    }

    function startVote(address _implementation) public {
        require(
            msg.sender == proposer,
            "AdminProxy: only proposer can start vote"
        );
        // start vote
    }

    function cancelProposal(address _implementation) public {
        require(
            msg.sender == proposer,
            "AdminProxy: only proposer can cancel proposal"
        );
        // cancel proposal
    }

    function rejectImplementation(address _implementation) public {
        require(
            msg.sender == acceptor,
            "AdminProxy: only acceptor can reject implementation"
        );
        // reject implementation
    }

    function acceptImplementation(address _implementation) public {
        require(
            msg.sender == acceptor,
            "AdminProxy: only acceptor can accept implementation"
        );
        // accept implementation
    }

    function resetToERC20() public {
        require(msg.sender == acceptor || msg.sender == proposer);
        // view only ERC20 implementation
    }
}
