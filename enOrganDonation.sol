// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.19;
pragma abicoder v2;

import "fhevm/lib/TFHE.sol";

// pragma experimental ABIEncoderV2;

contract medicalrecord {

    address owner = msg.sender;
    address public blankAddress;    
    uint matchIDMain;   
    euint32 one;
    euint32 thirty;
    euint32 onemillion;
    euint32 twenty;
    euint32 zero;

    struct reqSpec {
        bool status;
        address recipient;
        bytes32 hash;
        BloodType bloodType;
        uint organSize;
        uint height;
        uint weight;
        euint32 condition;
        uint age;
        address hospital;
        address donor;
        address bestMatch;
        address [] bestMatchs;
    }

    struct donaSpec {
        bool status;
        address donor;
        bytes32 hash;
        BloodType bloodType;
        uint organSize;
        uint height;
        uint weight;
        euint32 condition;
        uint age;
        address hospital;
        bool alive;
        address recipient;
        address bestMatch;
        address [] bestMatchs;
        string [] track;
    }

    struct organ{
        uint did;
        uint rid;
        mapping(uint => reqSpec) reqSpecs;
        mapping(uint => donaSpec) donaSpecs;
    }
    
    mapping(string => organ) organs;

    enum BloodType{A, B, AB, O}

    struct numList{
        string organ;
        euint32 [] nums;
        uint [] userID;
        uint mainID;
        bool raccept;
        bool rreject;
        bool daccept;
        bool dreject;
        bool sorted;
        uint timee;
        bool donation;
    }

    mapping (uint => numList) numLists;

    function hospitalReqReg(
        string memory _organ, 
        uint _organSize, 
        uint _height, 
        uint _weight, 
        uint _age,
        euint32 _condition, 
        BloodType _bloodType, 
        address _recipient,
        address _donor
        ) public returns(uint){
        
            organs[_organ].rid++;
            uint _id = organs[_organ].rid;
            organs[_organ].reqSpecs[_id].status = true;
            organs[_organ].reqSpecs[_id].recipient = _recipient;
            organs[_organ].reqSpecs[_id].hash = sha256(abi.encodePacked(_recipient));
            organs[_organ].reqSpecs[_id].organSize = _organSize;
            organs[_organ].reqSpecs[_id].height = _height;
            organs[_organ].reqSpecs[_id].weight = _weight;
            organs[_organ].reqSpecs[_id].bloodType = _bloodType;
            organs[_organ].reqSpecs[_id].condition = _condition;
            organs[_organ].reqSpecs[_id].age = _age;
            organs[_organ].reqSpecs[_id].hospital = msg.sender;
            organs[_organ].reqSpecs[_id].donor = _donor;
     
        return(_id);
    }

    function hospitalDonaReg(
        string memory _organ, 
        uint _organSize, 
        uint _height, 
        uint _weight, 
        uint _age,
        euint32 _condition, 
        bool _alive,
        BloodType _bloodType,
        address _donor,
        address _recipient 
        
        ) public returns(uint){
            organs[_organ].did++;
            uint _id = organs[_organ].did;
            organs[_organ].donaSpecs[_id].status = true;
            organs[_organ].donaSpecs[_id].donor = _donor;
            organs[_organ].donaSpecs[_id].hash = sha256(abi.encodePacked(msg.sender));
            organs[_organ].donaSpecs[_id].organSize = _organSize;
            organs[_organ].donaSpecs[_id].height = _height;
            organs[_organ].donaSpecs[_id].weight = _weight;
            organs[_organ].donaSpecs[_id].bloodType = _bloodType;
            organs[_organ].donaSpecs[_id].condition = _condition;
            organs[_organ].donaSpecs[_id].age = _age;
            organs[_organ].donaSpecs[_id].hospital = msg.sender;
            organs[_organ].donaSpecs[_id].alive = _alive;
            organs[_organ].donaSpecs[_id].recipient = _recipient;

        return(_id);
    }
    
    function turnFalse(uint _id, string memory _organ) public {
        organs[_organ].reqSpecs[_id].status = false;
    }

    function matchingListDonor(uint _ids, euint32 _iid, string memory _organ) public returns(uint) { //Donor trying to find a suitable recipient.      
        require(organs[_organ].donaSpecs[_ids].status == true, "the entered ID is not available");
        euint32 score;
        uint matchID = matchIDMain;
        matchIDMain++;
        numLists[matchID].organ = _organ;
        numLists[matchID].mainID = _ids;

        for(uint i = 1; i <= organs[_organ].rid; i++){
            
            score = thirty;
            uint _id = i;
            if(organs[_organ].reqSpecs[_id].status == true && (organs[_organ].donaSpecs[_ids].bloodType == organs[_organ].reqSpecs[_id].bloodType || compareBlood(organs[_organ].donaSpecs[_ids].bloodType, organs[_organ].reqSpecs[_id].bloodType) == true)){
                uint a;
                if(organs[_organ].donaSpecs[_ids].alive == false){
                    if(organs[_organ].reqSpecs[_id].hospital == organs[_organ].donaSpecs[_ids].hospital){score = TFHE.add(score, one);}
                    a = findDonorID(organs[_organ].reqSpecs[_id].donor, _organ);
                    if(organs[_organ].reqSpecs[_id].donor == organs[_organ].donaSpecs[a].donor && organs[_organ].donaSpecs[a].recipient != blankAddress){score = TFHE.add(score, twenty);} //checking if recipient came with a donor
                    if(organs[_organ].reqSpecs[_id].organSize == organs[_organ].donaSpecs[_ids].organSize){score = TFHE.add(score, one);}
                    if(organs[_organ].reqSpecs[_id].height == organs[_organ].donaSpecs[_ids].height){score = TFHE.add(score, one);}
                    if(organs[_organ].reqSpecs[_id].weight == organs[_organ].donaSpecs[_ids].weight){score = TFHE.add(score, one);}
                    if(organs[_organ].reqSpecs[_id].age == organs[_organ].donaSpecs[_ids].age){score = TFHE.add(score, one);}
                    score = TFHE.add(score, organs[_organ].reqSpecs[_id].condition);
                    score = TFHE.mul(score, onemillion);
                    score = TFHE.sub(TFHE.add(score, onemillion), _iid);
                    numLists[matchID].nums.push(score);
                    numLists[matchID].userID.push(_id);
                }else {
                    a = findDonorID(organs[_organ].reqSpecs[_id].donor, _organ);
                    if(organs[_organ].reqSpecs[_id].donor == organs[_organ].donaSpecs[a].donor && organs[_organ].donaSpecs[a].recipient != blankAddress){score = score + twenty;} //checking if recipient came with a donor
                    if(organs[_organ].reqSpecs[_id].organSize == organs[_organ].donaSpecs[_ids].organSize){score = TFHE.add(score, one);}
                    if(organs[_organ].reqSpecs[_id].height == organs[_organ].donaSpecs[_ids].height){score = TFHE.add(score, one);}
                    if(organs[_organ].reqSpecs[_id].weight == organs[_organ].donaSpecs[_ids].weight){score = TFHE.add(score, one);}
                    if(organs[_organ].reqSpecs[_id].age == organs[_organ].donaSpecs[_ids].age){score = TFHE.add(score, one);}
                    score = TFHE.add(score, organs[_organ].reqSpecs[_id].condition);
                    score = TFHE.mul(score, onemillion);
                    score = TFHE.sub(TFHE.add(score, onemillion), _iid);
                    numLists[matchID].nums.push(score);
                    numLists[matchID].userID.push(_id);
                }
            }
        }
        numLists[matchID].donation = true;
        numLists[matchID].timee = block.timestamp;
        decendingSort(matchID);
        return (matchID);
        
    }

    // function matchingListReci(uint _ids, euint32 _iid, string memory _organ)public returns(uint){// Recipient trying to find a suitabel donor.
    //     require(organs[_organ].reqSpecs[_ids].status == true, "the entered ID is not available");

    //     euint32 score;
    //     uint matchID = matchIDMain;
    //     matchIDMain++;
    //     numLists[matchID].organ = _organ;
    //     numLists[matchID].mainID = _ids;


    //     for(uint i = 1; i <= organs[_organ].did; i++){
    //         score = thirty;
    //         uint _id = i;
    //         if(organs[_organ].donaSpecs[_id].status == true && (organs[_organ].donaSpecs[_id].bloodType == organs[_organ].reqSpecs[_ids].bloodType || compareBlood(organs[_organ].donaSpecs[_id].bloodType, organs[_organ].reqSpecs[_ids].bloodType) == true)){
    //             uint a = findRecipientID(organs[_organ].donaSpecs[_id].recipient, _organ);
    //             if(organs[_organ].donaSpecs[_id].donor == organs[_organ].reqSpecs[a].donor && organs[_organ].donaSpecs[_id].recipient != blankAddress){score = TFHE.add(score, twenty);}
    //             if(organs[_organ].donaSpecs[_id].organSize == organs[_organ].reqSpecs[_ids].organSize){TFHE.add(score, one);}
    //             if(organs[_organ].donaSpecs[_id].height == organs[_organ].reqSpecs[_ids].height){score = TFHE.add(score, one);}
    //             if(organs[_organ].donaSpecs[_id].weight == organs[_organ].reqSpecs[_ids].weight){score = TFHE.add(score, one);}
    //             if(organs[_organ].donaSpecs[_id].age == organs[_organ].reqSpecs[_ids].age){score = TFHE.add(score, one);}
    //             score = TFHE.mul(score, onemillion);
    //             score = TFHE.sub(TFHE.add(score, onemillion), _iid);
    //             numLists[matchID].nums.push(score);
    //             numLists[matchID].userID.push(_id);
    //             // score = TFHE.add(score, one);

    //         }
    //     }
    //     numLists[matchID].timee = block.timestamp;
    //     decendingSort(matchID);
    //     return (matchID);
    // }

    function compareBlood (BloodType _bloodTypeDonor, BloodType _bloodTypeReci) private pure returns(bool){

        bool aaa;
        if((_bloodTypeReci == BloodType.A || _bloodTypeReci == BloodType.AB) && _bloodTypeDonor == BloodType.A){
            aaa = true;
        }else if ((_bloodTypeReci == BloodType.B || _bloodTypeReci == BloodType.AB) && _bloodTypeDonor == BloodType.B ){
            aaa = true;
        }else if (_bloodTypeReci == BloodType.AB && _bloodTypeDonor == BloodType.AB){
            aaa = true;
        }else if ((_bloodTypeReci == BloodType.A || _bloodTypeReci == BloodType.B || _bloodTypeReci == BloodType.AB || _bloodTypeReci == BloodType.O) && _bloodTypeDonor == BloodType.O){
            aaa = true;
        }
        return (aaa);
    }
    
    function decendingSort(uint _matchID) public {
            numLists[_matchID].nums.push(zero);
            numLists[_matchID].userID.push(0);
            numLists[_matchID].sorted = true;
            for(uint j = 0; j < numLists[_matchID].nums.length-2; j++){ 
                sortd(_matchID);
            }
            numLists[_matchID].nums.pop();
            numLists[_matchID].userID.pop();
                
    }
    
    function sortd (uint _matchID) private {
        for (uint i = 0; i < numLists[_matchID].nums.length-2; i++){
            // ebool isequal = TFHE.lt(numLists[_matchID].nums[i], numLists[_matchID].nums[i+1]);
            // ebool defaultbool; 
            if(TFHE.decrypt(TFHE.lt(numLists[_matchID].nums[i], numLists[_matchID].nums[i+1]))){
                euint32 currentNum = numLists[_matchID].nums[i];
                uint currentID = numLists[_matchID].userID[i];
                numLists[_matchID].nums[i] = numLists[_matchID].nums[i+1];
                numLists[_matchID].userID[i] = numLists[_matchID].userID[i+1];
                numLists[_matchID].nums[i + 1] = currentNum;
                numLists[_matchID].userID[i + 1] = currentID;
            }
        }
    }

    function enSortd (uint _matchID) private {
        for (uint i = 0; i < numLists[_matchID].nums.length-2; i++){
            if(TFHE.decrypt(numLists[_matchID].nums[i]) < TFHE.decrypt(numLists[_matchID].nums[i+1])){
                euint32 currentNum = numLists[_matchID].nums[i];
                uint currentID = numLists[_matchID].userID[i];
                numLists[_matchID].nums[i] = numLists[_matchID].nums[i+1];
                numLists[_matchID].userID[i] = numLists[_matchID].userID[i+1];
                numLists[_matchID].nums[i + 1] = currentNum;
                numLists[_matchID].userID[i + 1] = currentID;
            }
        }
    }

    function checkListAll1 (uint _matchID) public view returns(euint32 [] memory){
        return(numLists[_matchID].nums);
    }
    
    function checkIDList(uint _matchID) public view returns(uint [] memory){
        return (numLists[_matchID].userID);
    }

    function viewDonor(uint _id, string memory _organ) public view returns(donaSpec memory){
        return(organs[_organ].donaSpecs[_id]);
    }

    function viewRecipient(uint _id, string memory _organ) public view returns(reqSpec memory){
        return(organs[_organ].reqSpecs[_id]);
    }

    function findDonorID(address _donorAddress, string memory _organ) public view returns(uint){
        uint a;
        for (uint i = 1; i <= organs[_organ].did; i++){
            if(organs[_organ].donaSpecs[i].donor == _donorAddress){
                a = i;
            }
        }

        return(a);
    }

    function findRecipientID(address _recipientAddress, string memory _organ) public view returns(uint){
        uint a;
        for (uint i = 1; i <= organs[_organ].rid; i++){
            if(organs[_organ].reqSpecs[i].recipient == _recipientAddress){
                a = i;
            }
        }
        return(a);
    }

    function donorAcceptance(uint _matchID, bool _response)public {
        // uint recipientID = numLists[_matchID].userID[0];
        require(organs[numLists[_matchID].organ].donaSpecs[numLists[_matchID].mainID].status == true, "This donor is not available");
        require(organs[numLists[_matchID].organ].donaSpecs[numLists[_matchID].mainID].donor == msg.sender, "You are not the owner of the account");
        if (_response == true && numLists[_matchID].daccept == false && numLists[_matchID].dreject == false){
            numLists[_matchID].daccept = true;
        }else if(_response == false && numLists[_matchID].daccept == false && numLists[_matchID].dreject == false){
            numLists[_matchID].dreject = true;
            decendingSort(_matchID);
        }

        deactivate(_matchID);
                
    }

    function recipientAcceptance(uint _matchID, bool _response)public{
        
        if (_response == true && numLists[_matchID].raccept == false && numLists[_matchID].rreject == false){
            numLists[_matchID].raccept = true;
        }else if(_response == false && numLists[_matchID].raccept == false && numLists[_matchID].rreject == false){
            numLists[_matchID].nums[0] = zero;
            numLists[_matchID].userID[0] = 0;
            decendingSort(_matchID);
        }

        deactivate(_matchID);

    }

    function deactivate (uint _matchID) public {
        uint recipientID = numLists[_matchID].userID[0];
        string memory _organ = numLists[_matchID].organ;
        uint _id = numLists[_matchID].mainID;
        if(numLists[_matchID].daccept == true && numLists[_matchID].raccept == true){
            organs[_organ].donaSpecs[_id].status = false;
            organs[_organ].reqSpecs[recipientID].status = false;
        }
        
        
    }

    // function removeFirstCandidate (uint _matchID) public {
    //     require(numLists[_matchID].raccept == false, "The recipient has accepted");
    //     if(numLists[_matchID].timee  + 60 <= block.timestamp){
    //         numLists[_matchID].nums[0] = zero;
    //         numLists[_matchID].userID[0] = 0; 
    //         decendingSort(_matchID);
    //         numLists[_matchID].timee = block.timestamp;
    //     }
    // }

    function bestMatch(uint _matchID) public view returns(string memory, bool, uint, uint){
        return(numLists[_matchID].organ, numLists[_matchID].donation, numLists[_matchID].mainID, numLists[_matchID].userID[0]);
    }

    function updateTrack(string memory _organ, uint _id, string memory _update)public{
        organs[_organ].donaSpecs[_id].track.push(_update);
    }

    function viewTrack(string memory _organ, uint _id) public view returns(string [] memory){
        return organs[_organ].donaSpecs[_id].track;
    }

    function viewStore(uint _matchID)public view returns(numList memory){
        return (numLists[_matchID]);
    }

    function checkAcceptance (uint _matchID)public view returns(bool, bool, bool, bool){
        return(numLists[_matchID].daccept, numLists[_matchID].dreject, numLists[_matchID].raccept, numLists[_matchID].rreject);
    }

}
