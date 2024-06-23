// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./GameAssests.sol";
import "./contracts/token/ERC20/ERC20.sol";


// Implemented ERC-721 as Game Assests like heroes, power, monsters, kingdom etc..
// Implemented ERC-20 as Game Currency like Money. will be used for buying game assests.
// This contract will act as a liquidity pool , where all the tokens, ethers(wei) and NFTs will be stored 
// for trade and exchange, auction.


// wei <---> Tokens
// Tokens -----> NFTs , NFTs can be auctioned for tokens

contract MortalGame is ERC20{


    event rpsGameResult(string indexed res);


    struct Player{
        address playerAddress;
        uint score;
    }

    address private immutable owner;


// It was exceding the gas limit thats why firstly i deployed the gameAssets and then used that address here.

    GameAssests private gameAsset = GameAssests(0x8114Bb9e8C5Dc2279c3E85dc2867D1492f9d5C15);

    mapping(uint => bool) private isAvailableAsset;
    Player[] public leaderBoard;

    mapping(address=> uint) private leaderBoardIndex;
    mapping(address => bool)private inLeaderBoard;
     address private lastHighestOwner;
    uint private lastHighest;

    uint[] private tokenIdNFTCollection;

    modifier onlyOwner{
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner,"You are not the owner");
    }


//(working)


    constructor() ERC20("MortalGame","MGT"){

        owner = msg.sender;
        _mint((address(this)),100000 * 10 ** 18);
    }

    // (working)

    function mintMoreGameCurrencty(uint _amount) external onlyOwner{
        _mint((address(this)), _amount * 10 **18);
    }


    function getGameAssets(uint _choice) external onlyOwner{
        gameAsset.gameAssetMint((address(this)), _choice, msg.sender);
    }

///@notice : To buy tokens from the game (exchange ethers for tokens) 1 token = 1000 wei (working)
    function BuyTokens(uint _tokenAmount) external payable {
        require(balanceOf((address(this))) >= _tokenAmount,"Transaction unsuccessuful");
        uint requiredWei = _tokenAmount * 1000;
        require(msg.value >= requiredWei,"Not enough wei paid");

        uint returnAmount = msg.value - requiredWei;
        (bool res,) = payable(msg.sender).call{value: returnAmount}("");
        require(res,"Can't return the money");
        _transfer((address(this)),msg.sender,_tokenAmount);
    }

///@notice : To exchange Token for some General NFTs( working)
function directBuyNFTs(uint _tokenAmount,uint _NFTID) external{
    require(balanceOf(msg.sender)>=_tokenAmount,"Not Enough tokens in the account");
   bool res =  transfer(address(this),_tokenAmount);
   require(res,"Not successful");
   if((_NFTID < gameAsset.totalAssetsMinted()) && gameAsset.balanceOf(address(this)) > 0 && gameAsset.ownerOf(_NFTID) == address(this)) {
        toTransferNFT(msg.sender,_NFTID);
   }else{
    rewardBasicNFTs(msg.sender,_NFTID);
   }
}

///@notice Rewarding NFTS
    function rewardBasicNFTs(address _receiver, uint _choice)internal {
        gameAsset.gameAssetMint(_receiver, _choice, msg.sender);
    }
    function rewardUniqueNFTs(address _receiver, uint _choice) internal{
        gameAsset.uniqueAssetMint(_receiver, _choice, msg.sender);
    }
    function rewardSpecialNFTs(address _receiver, uint _choice) internal{
        gameAsset.specialAssetMint(_receiver, _choice, msg.sender);
    }

///@notice Rewarding Tokens (working)

function rewardTokens(address _receiver, uint _amount) external{

    if(msg.sender == owner){
        require(balanceOf((address(this)))>= _amount,"Not enought Tokens in the liquidity pool");
       _transfer((address(this)), _receiver, _amount);
    }else{
         require(balanceOf(msg.sender) >=_amount);
         bool res = transfer( _receiver, _amount);
        require(res,"Tokens Transfer Unsuccessful");
    }
}

///@notice : For NFT Auction (see this later)

    struct AuctionData{
        address seller;
        uint NFTID;
    }
    uint auctionCounter;

    AuctionData[] public auction;
    function forAuctionNFT(uint _tokenID) external{
        gameAsset.transferAsset(msg.sender,address(this),_tokenID);
        auction.push(AuctionData(msg.sender,_tokenID));
        isAvailableAsset[_tokenID] = true;
    }


        ///@notice : Auction for Buying the NFTs (complete)

      function auctionBuyNFT(uint _tokenAmount) external{
        require(balanceOf(msg.sender) >= _tokenAmount,"Not enough token with the bidder");
        if(_tokenAmount > lastHighest){
            transfer(address(this), _tokenAmount);
            if(lastHighestOwner!=address(0)){
                  _transfer((address(this)),lastHighestOwner,lastHighest);
            }
            lastHighest = _tokenAmount;
            lastHighestOwner = msg.sender;
            
        }
      }

      ///@notice sending the nft to the highest bidder.
      // sending the 80% of tokens to the seller

      function finishAuction() external onlyOwner{
        if(auction[auctionCounter].seller != address(0)){
            uint profit = (lastHighest /100)*20;
            _transfer(address(this), auction[auctionCounter].seller, lastHighest - profit);
            gameAsset.transferAsset((address(this)),lastHighestOwner,auction[auctionCounter].NFTID);
            auctionCounter++;
            lastHighest = 0;
            lastHighestOwner = address(0);
        }
      }


//

    function getOwner() external view returns(address){
        return gameAsset.getOwner();
    }




///@notice : To sell his/her nft to the liquidity Pool for some amount of tokens. 
      function toSellNFT(uint _tokenID) external {
        gameAsset.transferAsset(msg.sender,(address(this)),_tokenID);
        _transfer(address(this), msg.sender, 10000);
      }

      function toTransferNFT(address _recepient, uint _tokenID) internal{
        gameAsset.transferAsset((address(this)), _recepient, _tokenID);
      }

// To transfer my NFT to some friend.
      function transferNFT(address _recepient, uint _tokenID) external {
        require(_recepient != address(0));
        gameAsset.transferAsset(msg.sender,_recepient, _tokenID);
      }



    ///@notice Stone Paper Scissor Game.
    // 0 = Stone
    // 1 = Paper
    // 2 = Scissor
 
    function stonePaperScissor(uint _input) internal view returns(bool){
        require(_input < 3);
       uint machine =  machineRandomNumber()%3;
       if(_input == machine){
            return false;
       }else if (_input == 0 && machine == 1 || _input == 1 && machine == 2 || _input == 2 && machine == 0){
            return false;
       }else{
            return true;
       }

    }

    function playRockPaperScissor(uint _input)external returns(string memory) {

        bool res = playWithSystem(_input);
        if(res){
            emit rpsGameResult("You won");
            // adjustRanking();
            return "You won";
        }else{
            emit rpsGameResult("you lost");
            return "You Lost";
        }
        
    }

    function playWithSystem(uint _choice) internal returns(bool){
        bool res = stonePaperScissor(_choice);
        if(res == true && inLeaderBoard[msg.sender]!=false){
            // return leaderBoard[leaderBoardIndex[msg.sender]];
            leaderBoard[leaderBoardIndex[msg.sender]].score = leaderBoard[leaderBoardIndex[msg.sender]].score + 1;
           return true;

        }else{
            return false;
            
        }
      
        
    }

    function guessTheNumber(uint _inputNumber) internal returns(bool,uint){
        uint machine = machineRandomNumber()%5;

        if(_inputNumber == machine){
            leaderBoard[leaderBoardIndex[msg.sender]].score = leaderBoard[leaderBoardIndex[msg.sender]].score + 2;
            return (true,machine);
        }else{
            return (false,machine);
        }    
    }

    function guessTheNumberAgainstSystem(uint _inputNumber) external returns(string memory){

        (bool res, uint number ) = guessTheNumber(_inputNumber);
        string memory message;
        
       
        if(res){
             message = "You won the number was indeed ";
            //  adjustRanking();
            return  string.concat(message, Strings.toString(number));
        }
         message = "You Lost the number was ";
        
        return  string.concat(message, Strings.toString(number));
    }





    function machineRandomNumber() internal view returns(uint){
      uint val =  uint256(keccak256(abi.encodePacked(block.timestamp,block.coinbase)));
    return val;
    }


///@notice : To get all the NFT ids which are held by me

    function ownAssets() external view returns(uint[] memory) {
        return gameAsset.getOwnNfts(msg.sender);
    }

///@notice : To get all the NFT ids which are held by the game(contract)
    function contractAssets() external view returns(uint[] memory){
        return gameAsset.getOwnNfts(address(this));
    }


    ///@notice Register the user in the leaderBoard.

    function registerPlayer()external {
        if(inLeaderBoard[msg.sender]==false){
            inLeaderBoard[msg.sender] = true;
            leaderBoardIndex[msg.sender] = leaderBoard.length;
            Player memory newPlayer = Player(msg.sender,0);
            leaderBoard.push(newPlayer);
        }
    }


    function adjustRanking() public {
        uint l = leaderBoard.length;
        if(l <= 1) return;
   
        if(l > 1){
            quickSort(0,l-1);
        }
    }

    ///applying Quick sort. (implementing with the help of sorting technique of quickSort)

     function quickSort(uint left, uint right) internal {
        if (left >= right) return;

        uint pivotIndex = (left + right) / 2;
        uint pivotValue = leaderBoard[pivotIndex].score;
        uint i = left;
        uint j = right;

        while (i <= j) {
            while (i< j && leaderBoard[i].score > pivotValue) {
                i++;
            }
            while ( j >= 0 && leaderBoard[j].score < pivotValue) {
                if(j==0) break;
                j--;
            }
            if (i <= j) {
                Player memory temp = leaderBoard[i];
                leaderBoard[i] = leaderBoard[j];
                leaderBoard[j] = temp;
                 leaderBoardIndex[leaderBoard[i].playerAddress] = i;
                leaderBoardIndex[leaderBoard[j].playerAddress] = j;
                i++;
                if(j==0) break;
                j--;
            }
        }

        if (left < j) {
            quickSort(left, j);
        }
        if (i < right) {
            quickSort(i, right);
        }
    }


    function getRankings() external view returns(Player[] memory){
        
        return leaderBoard;
    }


    ///@notice reward after ending the season 
    // special NFT to rank 1 player
    // unique NFT to rank 2 and rank 3 player.

    function endSeason(uint _speicalID, uint _uniqueID) external onlyOwner{
        adjustRanking();
        uint l = leaderBoard.length;

        if(l == 1){
            rewardSpecialNFTs(leaderBoard[0].playerAddress, _speicalID);

         }else if(l == 2){
             rewardSpecialNFTs(leaderBoard[0].playerAddress, _speicalID);
              rewardUniqueNFTs(leaderBoard[1].playerAddress,_uniqueID);
        }else{
            rewardSpecialNFTs(leaderBoard[0].playerAddress, _speicalID);
            rewardUniqueNFTs(leaderBoard[1].playerAddress,_uniqueID);
            rewardUniqueNFTs(leaderBoard[2].playerAddress,_uniqueID);
        }

       // emptying the index records
        for(uint i = 0;i<l;i++){
           leaderBoardIndex[leaderBoard[i].playerAddress] = 0;
        }
        //emptying the whole player list.
        delete leaderBoard;
       

    }


    ///@notice : Owner will be able to withdraw all funds and NFTs from the contract in case of any problem
    function withdrawAllTokens() external onlyOwner{
        _transfer((address(this)), owner , balanceOf(address(this))); 
       
    }
    function withAllEth() external onlyOwner{
        (bool resMsg, ) = payable (owner).call{value:address(this).balance}("");
        require(resMsg);
    }
    function withdrawAllNFT(uint _NFTID) external onlyOwner{
         gameAsset.transferAsset(address(this), owner, _NFTID);
    }


///@notice to receive external ethers.
    receive() external payable { }

    
}