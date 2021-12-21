// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Auction {

    struct Product {
        address _owner;
        uint highestBid;
        address highestBidder;
        uint duration;
        bool isActive;
        bool isSold;
        uint startBlock;
    }

    mapping(uint => Product) public idToProduct;
    mapping(address => mapping(uint => uint)) usersBidAmount;
    address Owner;
    bool public Paused;
    Product[] _product;

    modifier idExsists(uint _productId) {
        require(_productId < _product.length);
        _;
    }

    modifier isContractPaused() {
        require(Paused == false, "Contract is paused");
        _;
    }

    constructor (bool _paused) public {
        Owner = msg.sender;
        Paused = _paused;
    } 

    function setPaused(bool _paused) public {
        require(msg.sender == Owner);
        Paused = _paused;
    }


    function putProduct(uint _price, uint _duration) public isContractPaused {

        idToProduct[_product.length] = Product(msg.sender, _price, msg.sender, _duration, true, false, block.number);
        _product.push(idToProduct[_product.length]);

    }

    function bid(uint _auctionId) public payable idExsists(_auctionId) isContractPaused {

        Product storage product = idToProduct[_auctionId];
        require(!product.isSold, "product already sold");
        require(product.isActive, "Currently not in sale");
        require(msg.value > product.highestBid, "Place a higher bid");

        product.highestBid = msg.value;
        product.highestBidder = msg.sender;
        usersBidAmount[msg.sender][_auctionId] = msg.value;
    }

    function claim(uint _auctionId) public payable idExsists(_auctionId) isContractPaused {

        Product storage product = idToProduct[_auctionId];
        require(block.number < product.startBlock + product.duration, "Auction not over yet");
        require(!product.isSold, "product already sold");
        require(product.isActive, "Currently not in sale");
        require(product.highestBidder == msg.sender, "You are not the winner");

        payable(product._owner).transfer(usersBidAmount[msg.sender][_auctionId]);
        product._owner = msg.sender;
        product.isActive = false;
        product.isSold = true;
    }

    function getBidBack(uint _auctionId) public idExsists(_auctionId) isContractPaused {

        Product storage item = idToProduct[_auctionId];
        require(msg.sender != item.highestBidder, "Can't get back the bid since you are the highest bidder");
        
        payable(msg.sender).transfer(usersBidAmount[msg.sender][_auctionId]);
    }

    function viewBalance() public view returns(uint) {
        return address(this).balance;
    }
}
