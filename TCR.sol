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

    //in the end of the contract, it will be either setted to true or not, depending on the voting process
    bool affirmationPassed;

    uint voterGroupCounter; //global counter that will allocate new voters in different groups in a circular way

    //when each round will finish and not receive votes anymore
    uint roundOneClosesAt;
    uint roundTwoClosesAt;
    uint roundThreeClosesAt;

    //flag to determine if a contract ends before roundthreeClosesAt, in case there is no objections
    bool contractEnded;

        //mappings

    //the matrix that keeps the number of votes in each statement of the contract in a group, given by that or another group
    //groupToGroupToStatementsVoteCount[Group who votes][Group who receives the votes][Vote Count]
    mapping (uint => mapping(uint => mapping(uint => uint))) public groupToGroupToStatementsVoteCount;
    
    //checks if a group created an objection (round 1) or a rebuttal (round 2)
    mapping (uint => bool) public groupToIfObjectionExistsInGroup;
    //There can be different rebuttals for the same objection
    mapping (uint => mapping(uint => bool)) public groupToGroupToIfRebuttalExistsInGroup;

        //Mappings to manage Voter informations

    //links a voter to his group
    mapping (address => uint) public voterAddressToVoterGroup;

    //the token account of the voter, where he will receive rewards
    mapping (address => uint) public voterAddressToVoterBalance;

    //determines if voter already voted or createdObjection
    mapping (address => bool) public voterAddressToIfVoted;
    mapping (address => bool) public voterAddressToIfCreatedObjection;


    //determines if voter is already in a group
    mapping (address => bool) public voterAddressToIfVoterIsInGroup;

    //determines the vote of each voter, in each round
    mapping (address => bool) public voterAddressToVoteRoundOne;
    mapping (address => mapping(uint => bool)) public voterAddressToGroupAnalysedToVoteRoundTwo;
    mapping (address => bool) public voterAddressToVoteRoundThree;

    //determines the winning statement in each round
    mapping (uint => bool) public groupToItswinningStatementRoundOne;
    mapping (uint => mapping(uint=> bool)) public groupToGroupToItswinningStatementRoundTwo;
    mapping (uint => bool) public groupToItswinningStatementRoundThree;

    //determines if a voter already reclaimed his tokens for each round
    mapping (address => bool) public voterAddressToIfReclaimedTokensRoundOne;
    mapping (address => bool) public voterAddressToIfReclaimedTokensRoundTwo;
    mapping (address => bool) public voterAddressToIfReclaimedTokensRoundThree;    

    //determines if Owner of the contract Finalized each round after its timespan ended, to begin next round
    bool finalizedRoundOne;
    bool finalizedRoundTwo;
    bool finalizedRoundThree;


    constructor(string memory _affirmationCID, uint _affirmationComplexity, uint _numberOfGroups) {
        //there needs to be at least 2 groups
        require(_numberOfGroups > 1, "invalid number of groups");

        _owner = msg.sender;

        //sets variables
        affirmationCID = _affirmationCID;
        affirmationComplexity = _affirmationComplexity;
        numberOfGroups = _numberOfGroups;

        //sets the time of rounds
        roundOneClosesAt = block.timestamp + (2) * 1 minutes;
        roundTwoClosesAt = roundOneClosesAt + (numberOfGroups)* 2 * 1 minutes;
        roundThreeClosesAt = roundTwoClosesAt + ((numberOfGroups)*(numberOfGroups - 1)) * 1 minutes;

    }

    //User Interface

    function assignToGroup() public notOwner {
        require(voterAddressToIfVoterIsInGroup[msg.sender] == false, "voter already assigned to group");
        
        //assigns a group to each user using a circular function based on the number of groups
        voterAddressToVoterGroup[msg.sender] = (voterGroupCounter % numberOfGroups);
        
        //counter increases to assigned next voter to a new group
        voterGroupCounter++;

        //voter is now assigned to group
        voterAddressToIfVoterIsInGroup[msg.sender] = true;    
    }


    //valid values {true -> votes on original affirmation}
    //             {false -> votes on objection of his group, if created}
    function voteRoundOne(bool vote) public notOwner {
        require(contractEnded == false, "contract already ended"); //if contract ended, cant receive votes
        require(voterAddressToIfVoted[msg.sender] == false, "voter already voted"); //voter cant vote again
        require(voterAddressToIfCreatedObjection[msg.sender] == false, "if created objection, can't vote");
        require(block.timestamp < roundOneClosesAt, "round 1 already finished"); //round already ended
        require(voterAddressToIfVoterIsInGroup[msg.sender] == true, "assign to a group before voting");
        
        //votes for objection
        if(vote == false) {
            //can only vote if objection exists in his group
            if(groupToIfObjectionExistsInGroup[voterAddressToVoterGroup[msg.sender]] == false){
                revert("You are voting for an objection, but it doesnt exist");
            }else{
                groupToGroupToStatementsVoteCount[voterAddressToVoterGroup[msg.sender]][voterAddressToVoterGroup[msg.sender]][1]++;
            }
        //votes for original affirmation
        }else{
            groupToGroupToStatementsVoteCount[voterAddressToVoterGroup[msg.sender]][voterAddressToVoterGroup[msg.sender]][0]++;
        }

        //voter can't vote again in this round
        voterAddressToVoteRoundOne[msg.sender] = vote;
        voterAddressToIfVoted[msg.sender] = true;
    }



    //valid values {true -> votes on objection}
    //             {false -> votes on rebuttal of his group, if created}
    //groupBeingAnalised -> ID of the group that will have their objection rebutted
    function voteRoundTwo(uint groupBeingAnalysed, bool vote) public notOwner {
        require(contractEnded == false, "contract already ended"); //if contract ended, cant receive votes
        require(voterAddressToIfVoted[msg.sender] == false, "voter already voted"); //voter cant vote again
        require(voterAddressToIfCreatedObjection[msg.sender] == false, "if created rebuttal, can't vote");
        require(block.timestamp < roundTwoClosesAt, "round 2 already finished"); //round already ended
        require(voterAddressToIfReclaimedTokensRoundOne[msg.sender] == true, "first reclaim your tokens from round 1 before round 2");
        require(voterAddressToVoterGroup[msg.sender] != groupBeingAnalysed, "can't vote for or against objection in your own group");
        require(groupToItswinningStatementRoundOne[groupBeingAnalysed] == false, "If there is no Objection from round 1, if cant go to round 2 voting");
        require(groupBeingAnalysed >=0 && groupBeingAnalysed < numberOfGroups, "Out of range group ID");

        //votes for rebuttal
        if(vote == false) {
            //can only vote if rebuttal exists in his group
            if(groupToGroupToIfRebuttalExistsInGroup[voterAddressToVoterGroup[msg.sender]][groupBeingAnalysed] == false){
                revert("You are voting for a rebuttal, but it doesnt exist");
            }else{
                groupToGroupToStatementsVoteCount[voterAddressToVoterGroup[msg.sender]][groupBeingAnalysed][2]++;
            }
        //votes for objection created in round 1 by that group
        }else{
            groupToGroupToStatementsVoteCount[voterAddressToVoterGroup[msg.sender]][groupBeingAnalysed][1]++;
        }

        //voter can't vote again in this round
        voterAddressToGroupAnalysedToVoteRoundTwo[msg.sender][groupBeingAnalysed] = vote;
        voterAddressToIfVoted[msg.sender] = true;

    }

    //valid values {true -> agrees with the group's decision}
    //             {false -> disagrees with group's decision}
    //groupBeingAnalised -> ID of the group that will have their objection rebutted
    function voteRoundThree(uint groupBeingAnalysed, bool vote) public notOwner {
        require(contractEnded == false, "contract already ended"); //if contract ended, cant receive votes
        require(voterAddressToIfVoted[msg.sender] == false, "voter already voted"); //voter cant vote again
        require(block.timestamp < roundThreeClosesAt, "round 3 already finished"); //round already ended
        require(voterAddressToIfReclaimedTokensRoundTwo[msg.sender] == true, "first reclaim your tokens from round 1 before round 2");
        require(groupBeingAnalysed >=0 && groupBeingAnalysed < numberOfGroups, "Out of range group ID");
        require(voterAddressToVoterBalance[msg.sender] > 100, "You must be an informed voter to be part of group Omega");
        if (vote == true){
            //group Omega will be group 0 for this round, so that all the informed voter be part of the same group
            groupToGroupToStatementsVoteCount[0][groupBeingAnalysed][3]++;
        }else{
            groupToGroupToStatementsVoteCount[0][groupBeingAnalysed][4]++;
        }
        voterAddressToIfVoted[msg.sender] = true;
    }

    //if objection exists, voter change his vote to it
    function changeVoteRoundOne() public notOwner {
        require(contractEnded == false, "contract already ended"); //if contract ended, cant receive votes
        require(voterAddressToIfVoted[msg.sender] == true, "first you have to vote in order to change vote"); //voter cant vote again
        require(voterAddressToIfCreatedObjection[msg.sender] == false, "if created objection, can't change vote");
        require(block.timestamp < roundOneClosesAt, "round 1 already finished"); //round already ended
        require(voterAddressToIfVoterIsInGroup[msg.sender] == true, "assign to a group before voting");
        require(groupToIfObjectionExistsInGroup[voterAddressToVoterGroup[msg.sender]] == true, "there is no objection to change the vote to");
        require(voterAddressToVoteRoundOne[msg.sender] == true, "you already voted for the objection");

        //removes a vote from affirmation and passes the vote to the objection
        groupToGroupToStatementsVoteCount[voterAddressToVoterGroup[msg.sender]][voterAddressToVoterGroup[msg.sender]][0]--;
        groupToGroupToStatementsVoteCount[voterAddressToVoterGroup[msg.sender]][voterAddressToVoterGroup[msg.sender]][1]++;

        //change user vote (false == objection)
        voterAddressToVoteRoundOne[msg.sender] = false;
    }

    //if rebuttal exists, voter change his vote to it
    function changeVoteRoundTwo(uint groupBeingAnalysed) public notOwner {
        require(contractEnded == false, "contract already ended"); //if contract ended, cant receive votes
        require(voterAddressToIfVoted[msg.sender] == true, "first you have to vote in order to change vote"); //voter cant vote again
        require(voterAddressToIfCreatedObjection[msg.sender] == false, "if created Rebuttal, can't change vote");
        require(block.timestamp < roundTwoClosesAt, "round 2 already finished"); //round already ended
        require(groupToGroupToIfRebuttalExistsInGroup[voterAddressToVoterGroup[msg.sender]][groupBeingAnalysed] == true, "Your group didnt create Rebuttal to change the vote to");
        require(voterAddressToGroupAnalysedToVoteRoundTwo[msg.sender][groupBeingAnalysed] == true, "you already voted for the objection");
        require(voterAddressToVoterGroup[msg.sender] != groupBeingAnalysed, "can't change vote in your own group");
        require(groupBeingAnalysed >=0 && groupBeingAnalysed < numberOfGroups, "Out of range group ID");


        //removes a vote from objection and passes the vote to the rebuttal 
        groupToGroupToStatementsVoteCount[voterAddressToVoterGroup[msg.sender]][groupBeingAnalysed][1]--;
        groupToGroupToStatementsVoteCount[voterAddressToVoterGroup[msg.sender]][groupBeingAnalysed][2]++;

        //change user vote (false == objection)
        voterAddressToGroupAnalysedToVoteRoundTwo[msg.sender][groupBeingAnalysed] = false;
    }

    function createObjection() public notOwner {
        require(contractEnded == false, "contract already ended"); //if contract ended, cant create objection
        require(voterAddressToIfVoted[msg.sender] == false, "if voted, can't create objection"); //voter cant vote again
        require(voterAddressToIfCreatedObjection[msg.sender] == false, "already created objection");
        require(block.timestamp < roundOneClosesAt, "round 1 already finished"); //round already ended
        require(voterAddressToIfVoterIsInGroup[msg.sender] == true, "assign to a group before creating objection");
        require(groupToIfObjectionExistsInGroup[voterAddressToVoterGroup[msg.sender]] == false, "group already created objection");


        groupToIfObjectionExistsInGroup[voterAddressToVoterGroup[msg.sender]] = true;
        voterAddressToIfCreatedObjection[msg.sender] = true;
        _increaseTime();

    }

    function createRebuttal(uint groupBeingAnalysed) public notOwner {
        require(contractEnded == false, "contract already ended"); //if contract ended, cant create objection
        require(voterAddressToIfVoted[msg.sender] == false, "if voted, can't create rebuttal"); //voter cant vote again
        require(voterAddressToIfCreatedObjection[msg.sender] == false, "already created Rebuttal");
        require(groupBeingAnalysed >=0 && groupBeingAnalysed < numberOfGroups, "Out of range group ID");
        require(block.timestamp < roundTwoClosesAt, "round 2 already finished"); //round already ended
        require(groupToItswinningStatementRoundOne[groupBeingAnalysed] == false, "group does not have an objection to be rebutted");
        require(groupToGroupToIfRebuttalExistsInGroup[voterAddressToVoterGroup[msg.sender]][groupBeingAnalysed] == false, "Your group already created a rebuttal to this objection");
        require(voterAddressToIfReclaimedTokensRoundOne[msg.sender] == true, "first reclaim your tokens from round 1 before round 2");
        require(voterAddressToVoterGroup[msg.sender] != groupBeingAnalysed, "can't create rebuttal in your own group");

        groupToGroupToIfRebuttalExistsInGroup[voterAddressToVoterGroup[msg.sender]][groupBeingAnalysed] = true;
        voterAddressToIfCreatedObjection[msg.sender] = true;
        _increaseTime();
    }

    //after each round is finalized by the Owner, if the voter voted for a winning statement, he can reclaim his tokens using this function
    function reclaimTokensAfterRoundOne() public {
        require(finalizedRoundOne == true, "Round 1 has to be finalized before reclaiming tokens!");
        require((voterAddressToIfVoted[msg.sender] == true || voterAddressToIfCreatedObjection[msg.sender]==true || msg.sender == _owner), "had to vote or create objections to receive tokens, or be the owner of the contract");
        require(voterAddressToIfReclaimedTokensRoundOne[msg.sender] == false, "already reclaimed your tokens for this round");

        //First case: if the affirmation passed
        if(affirmationPassed == true){
            //if you are the owner, you receive more tokens
            if(msg.sender == _owner){
                voterAddressToVoterBalance[msg.sender] += 100;
            }
        }

        //second: there is an objection in at least one group

        //if the voter voted for the winning statement in his group, receive tokens. Has to check if is not the creator of the objection
        if(voterAddressToVoteRoundOne[msg.sender] == groupToItswinningStatementRoundOne[voterAddressToVoterGroup[msg.sender]]){
            if(voterAddressToIfCreatedObjection[msg.sender] == false){
                voterAddressToVoterBalance[msg.sender] += 50;
            }
        }

        //if the voter created a winning objection in a group
        if(voterAddressToIfCreatedObjection[msg.sender] == true && groupToItswinningStatementRoundOne[voterAddressToVoterGroup[msg.sender]] == false){
            voterAddressToVoterBalance[msg.sender] += 70;
        }

        //set the reclaimed tokens flag to true for the voter
        voterAddressToIfReclaimedTokensRoundOne[msg.sender] = true;
        //resets vote flag for round 2
        voterAddressToIfVoted[msg.sender] = false;
        voterAddressToIfCreatedObjection[msg.sender] = false;

        
    }

    function reclaimTokensAfterRoundTwo() public {
        require(finalizedRoundTwo == true, "Round 2 has to be finalized before reclaiming tokens!");
        require((voterAddressToIfVoted[msg.sender] == true || voterAddressToIfCreatedObjection[msg.sender]==true || msg.sender == _owner), "had to vote or create objections to receive tokens, or be the owner of the contract");
        require(voterAddressToIfReclaimedTokensRoundTwo[msg.sender] == false, "already reclaimed your tokens for this round");

        for (uint i = 0; i < numberOfGroups; i++) {
            //cant receive tokens when the group analysed is his own group
            if(i != voterAddressToVoterGroup[msg.sender]){
                //if voter created rebuttal
                if(voterAddressToIfCreatedObjection[msg.sender] == true){
                    //and the rebuttal won
                    if(groupToGroupToItswinningStatementRoundTwo[voterAddressToVoterGroup[msg.sender]][i] == false){
                        voterAddressToVoterBalance[msg.sender] += 70;
                    }
                }
                //if the vote is equal to the winning statement
                else if(voterAddressToGroupAnalysedToVoteRoundTwo[msg.sender][i] == groupToGroupToItswinningStatementRoundTwo[voterAddressToVoterGroup[msg.sender]][i]) {
                    voterAddressToVoterBalance[msg.sender] += 50;
                }
            }
        }


        voterAddressToIfReclaimedTokensRoundTwo[msg.sender] = true;
        //resets vote flag for round 3
        voterAddressToIfVoted[msg.sender] = false;
        voterAddressToIfCreatedObjection[msg.sender] = false;

    }

    // function reclaimTokensAfterRoundThree() public {
    //     require(finalizedRoundThree == true, "Round 2 has to be finalized before reclaiming tokens!");
    //     require((voterAddressToIfVoted[msg.sender] == true || msg.sender == _owner), "had to vote or create objections to receive tokens, or be the owner of the contract");
    //     require(voterAddressToIfReclaimedTokensRoundThree[msg.sender] == false, "already reclaimed your tokens for this round");

    //     //group Omega analyses all the groups first
    //     for(uint i = 0; i < numberOfGroups; i++){

    //     }
    // }

    //auxiliar functions
    
    function finalizeRoundOne() public onlyOwner {
        require(contractEnded == false, "contract already ended");
        require(block.timestamp >= roundOneClosesAt, "round 1 timespan is not over yet!");
        require(finalizedRoundOne == false, "already finalized round 1!");

        //a flag to check if there is any group with a winning objection
        bool objectionFlag = false;

        //Checks winning statement in each group
        for(uint i = 0; i < numberOfGroups; i++) {
            if(groupToGroupToStatementsVoteCount[i][i][0] > groupToGroupToStatementsVoteCount[i][i][1]){
                groupToItswinningStatementRoundOne[i] = true;

            }else{
                objectionFlag = true; //there is at least one group in which an objection wins
            }

        }
        
        //if objectionFlag is false, there is no winning objection in round one, so the contract ends and the affirmation passes!
        if(objectionFlag == false){
            contractEnded = true;
            affirmationPassed = true;
        }
        // Round Finalized
        finalizedRoundOne = true;

        //set user flags to default for round 2
        voterAddressToIfCreatedObjection[msg.sender] = false;
    }

    function finalizeRoundTwo() public onlyOwner {
        require(block.timestamp >= roundTwoClosesAt, "round 2 timespan is not over yet!");
        require(finalizedRoundTwo == false, "already finalized round 2!");

        // i -> group voting
        // j -> group being analysed
        for(uint i = 0; i < numberOfGroups; i++){
            for(uint j = 0; j < numberOfGroups; j++){
                //Only analyse the groups that had objections winning in round 1
                if(groupToItswinningStatementRoundOne[j] == false){
                    // if objection has more votes than rebuttal
                    // true ->refers to objection
                    // false ->refers to rebuttal
                    if(groupToGroupToStatementsVoteCount[i][j][1] > groupToGroupToStatementsVoteCount[i][j][2]){
                        groupToGroupToItswinningStatementRoundTwo[i][j] = true;
                    }
                }
            }
        }

        // finalizes round
        finalizedRoundTwo = true;
    }

    function finalizeRoundThree() public onlyOwner {
        require(block.timestamp >= roundThreeClosesAt, "round 3 timespan is not over yet!");
        require(finalizedRoundThree == false, "already finalized round 3!");
        // i -> group being analysed by group Omega, in this case group 0
        for(uint i = 0; i < numberOfGroups; i++){
            if(groupToGroupToStatementsVoteCount[0][i][3] > groupToGroupToStatementsVoteCount[0][i][4]){
                groupToItswinningStatementRoundThree[i] = true;
            }
        }
        

        // finalizes round
        finalizedRoundThree = true;    
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

    function getMyBalance() public view returns(uint){
        return voterAddressToVoterBalance[msg.sender];
    }

    function statementVoteCount(uint _groupVoting, uint _groupBeingVoted, uint _statementVoteCount) public view returns(uint){
        return groupToGroupToStatementsVoteCount[_groupVoting][_groupBeingVoted][_statementVoteCount];
    }

    //when an objection or rebuttal is created, there needs to be more time for people to evaluate it.
    function _increaseTime() internal {
        roundOneClosesAt = roundOneClosesAt + 1 minutes;
        roundTwoClosesAt = roundTwoClosesAt + 1 minutes;
        roundThreeClosesAt = roundThreeClosesAt + 1 minutes;
    }
}
