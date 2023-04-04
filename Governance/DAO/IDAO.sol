// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IDAO {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    function propose(
        address[] memory targets,
        bytes[] memory calldatas,
        string memory description
    ) external  returns (uint256 proposalId);

    function castVote(uint256 proposalId, uint8 support) external payable  returns (uint256 balance);

    function withdraw(uint256 proposalId) external payable  returns (uint256);

    function queue(
        address[] memory targets,
        bytes[] memory calldatas,
        bytes32 descriptionHash) external  returns(uint256);

    function execute(
        address[] memory targets,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external payable  returns (uint256 proposalId);


    function hasVoted(uint256 proposalId, address account) external view returns (bool);

    function state(uint256 proposalId) external view  returns (ProposalState);

    function setBlockReward(uint newBlockReward) external;
    function blockReward() external view returns(uint);

    function updateDelay(uint256 newDelay) external;
    function votingDelay() external view returns (uint256);


}
