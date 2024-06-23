# Creating EVM subnet with Ava Labs

- Created my own (custom) Subnet using the Avalanche-Cli.

## Steps to Follow

- avalanche subnet create mortalSubnet (chain ID : 10284) (Token Symbol : MLG)
- avalanche subnet deploy mortalSubnet
- Importing the account & Copying the private key in the metamask.
- Adding the network through RPC URL and chain ID
- Interacting with the game using the REMIX IDE
- For Better Interaction i downloaded contracts folder from openzepellin

<img width="855" alt="image" src="https://github.com/PradeepSahhu/CustomSubnet/assets/94203408/94e1c7ab-cc77-4e5a-b32b-164c08b039c2">

<img width="354" alt="image" src="https://github.com/PradeepSahhu/CustomSubnet/assets/94203408/030b353b-e3af-4215-9ecd-edf6908d3755">

## Objective

This game consists of two contracts

- Game Asset (Every game asset like hero, land , kingdom) - ERC721
- Mortal Game( Main gaming concept and Game Currency in the form of tokens) - ERC20

Here Mortal Game Contract will act as a liquidity pool, it means every token, gaming asset or wei / ether will be stored and will be exchanged from here through the owner.

Owner will not store any token, asset,or wei in his account.

Owner will have control over few functionality like

- ending the season and rewarding the special and unique NFTs to the top 3 player,
- finishing the auction and rewarding the NFTs to the highest bidder.

## Code by Code Explanation.

```Solidity

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

```

This code is implemented as a game like in my Game (mortalGame) there are primarly two games to play.

- Playing stone paper scissor with the System
- Playing Guess the number with the sytem. (0-4)

Upon winning certain amount of points will be added to the player list and that way the player can climb on the leaderboard

```Solidity

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
```

This above endSeason function ends the season and reward the special and unique game assets (nfts) to the top three player and the empty the leaderboaard and the mapping of indexes.

```Solidity

    function registerPlayer()external {
        if(inLeaderBoard[msg.sender]==false){
            inLeaderBoard[msg.sender] = true;
            leaderBoardIndex[msg.sender] = leaderBoard.length;
            Player memory newPlayer = Player(msg.sender,0);
            leaderBoard.push(newPlayer);
        }
    }

```

This function is used to register the player in the game as the player without registration can't play the game and climb the leaderboard.

Actually what this function is doing is its checking if the caller is already in the leaderboard and if not then its assigning the index in the leaderboard array with its address and
initial point that is 0 and mapping that index with its address in the mapping of leaderBoardIndex and setting true in inLeaderBoard mapping.

```Solidity
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
```

This adjust ranking plays a very crucial functionality that is its adjusting the indexes of the players in the leaderboard list on the basis of their points(score) in the descending order manner such that the player with the highest score will be on 0th index and so on.
This function will be called before ending the season the the hastle to top player is computationally expensive.

It is implementing quicksort as a sorting algorithm.

## Assets Buying and Auctioning and sharing

Not only games but my Game `MortalGame` also provides Mechanism to buy, share or auction the NFTs (game assets)

- Players will be able to buy the tokens (game currency) through certain amount of wei/ethers. just like in real world we buy game assets like gun skins through real money.
- And through these tokens players will be able to buy the game assets like heroes, kingdom , land , weapons etc...
- Not only that if i have extra of something i can also auction it or transfer it to some of my friends.

  ### Function for auctioning.

  ```Solidity

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
  ```

  Before auctioning my NFT(game asset) i need it to transfer it to the liquidity pool that is to the contract and it will store my address through forAuctionNFT function.

  Now then it will be avaible for auctioning and players can bid on it through auctionBuyNFT function. This function stores the address and amount of the highest bidder and previous highes bidder address and amount is retransfered to it and the current highest bidder address is stored

  when the owner finishes the auction through this function.

  ```Solidity
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
  ```

  The NFT transfer to the highest bidder and 80% tokens transfer to the seller.

  Not only that the owner can also transfer/sell his/her NFTs to the contract itself as well through this.

  ```Solidity

  ///@notice : To sell his/her nft to the liquidity Pool for some amount of tokens.
      function toSellNFT(uint _tokenID) external {
        gameAsset.transferAsset(msg.sender,(address(this)),_tokenID);
        _transfer(address(this), msg.sender, 10000);
      }

  ```

  or the player can trasfer to some of his friends.

  ```Solidity

  // To transfer my NFT to some friend.
      function transferNFT(address _recepient, uint _tokenID) external {
        require(_recepient != address(0));
        gameAsset.transferAsset(msg.sender,_recepient, _tokenID);
      }
  ```

## Withdraw Functin

At certain scenerio, where the owner needs to withdraw all the funds, tokens or NFTs owner can do this thruogh withdraw functions.

```Solidity

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
```

## Complete Code

```Solidity


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./GameAssests.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


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


    GameAssests private gameAsset;

    mapping(uint => bool) private isAvailableAsset;
    Player[] private leaderBoard;

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
        gameAsset = new GameAssests(msg.sender);
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





```
