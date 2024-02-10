// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title newTCR
 * @dev Implements Token Curated Registry for decentralized code review system
 */

/**
Requirements:
    Owner:
        -> can submit a source code to be reviewed
        -> receive tokens if his affirmation passes
    
    Voter:
        -> can vote on statement or objections
        -> can create objections (phase 1)
        -> can create rebuttal to objection (phase 2)
        -> can approve source code or reject it based on objections (phase 3)
        -> has to receive tokens for participation

**/

contract TCR {
    
    //events

    //variables
    address private _owner;

    string affirmationCID;
    uint affirmationComplexity;
    uint numberOfGroups;

    uint voterGroupCounter; //global counter that will allocate new voters in different groups in a circular way

    //when each round will finish and not receive votes anymore
    uint roundOneClosesAt;
    uint roundTwoClosesAt;
    uint roundThreeClosesAt;

    //flag to determine if a contract ends before roundthreeClosesAt

    //mappings

    //the matrix that keeps the number of votes in each statement of the contract for each group
    mapping (uint => mapping(uint => uint)) public statementVoteCount;

    //checks if there is a group created an objection (round 1) or a rebuttal (round 2)
    mapping (uint => bool) public groupToIfObjectionExistsInGroup;
    mapping (uint => bool) public groupToIfRebuttalExistsInGroup;

    //links a voter to his group
    mapping (address => uint) public voterAddressToVoterGroup;

    //the token account of the user, where he will receive rewards
    mapping (address => uint) public voterAddressToVoterBalance;

    constructor(string memory _affirmationCID, uint _affirmationComplexity, uint _numberOfGroups) {
        //there needs to be at least 2 groups
        require(_numberOfGroups > 1, "invalid number of groups");

        //sets variables
        affirmationCID = _affirmationCID;
        affirmationComplexity = _affirmationComplexity;
        numberOfGroups = _numberOfGroups;

        //sets the time of rounds
        roundOneClosesAt = block.timestamp + (1) * 1 minutes;
        roundTwoClosesAt = roundOneClosesAt + (numberOfGroups) * 1 minutes;
        roundThreeClosesAt = roundTwoClosesAt + ((numberOfGroups)*(numberOfGroups - 1)) * 1 minutes;

    }

    //User Interface

    //valid values {0 -> votes on original affirmation}
    //             {1 -> votes on objection of his group, if created}
    function voteRoundOne(uint vote) public notOwner {

    }

    //valid values {1 -> votes on original affirmation}
    //             {2 -> votes on rebuttal of his group, if created}
    function voteRoundTwo(uint vote) public notOwner {

    }

    //valid values {2 -> votes on rebuttal}
    //             {3 -> votes AGAINT the rebuttal}
    function voteRoundThree(uint vote) public notOwner {

    }

    //if objection exists, voter change his vote to it
    function changeVoteRoundOne() public notOwner {

    }

    //if rebuttal exists, voter change his vote to it
    function changeVoteRoundTwo() public notOwner {

    }


    function createObjection() public notOwner {

    }

    function createRebuttal() public notOwner {

    }


    //after each round is finalized by the Owner, if the voter voted for a winning statement, he can reclaim his tokens using this function
    function reclaimTokens() public {

    }
 

    //auxiliar functions

    
    function finalizeRoundOne() public onlyOwner {

    }

    function finalizeRoundTwo() public onlyOwner {

    }

    function finalizeRoundThree() public onlyOwner {

    }
    

    //modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier notOwner() {
        require(msg.sender != _owner);
         _;
    }



}
