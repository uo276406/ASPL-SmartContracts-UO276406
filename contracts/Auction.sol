// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAuction.sol";


contract Auction is ERC721, ERC721Burnable, Ownable, IAuction {
    uint private auctionCounter;
    mapping(uint => Auction) private auctions;
    uint[] private activeAuctions;
    
    constructor(address initialOwner)
        ERC721("AuctionSystem", "AS")
        Ownable(initialOwner)
    {
        // Se crean por defecto inicialmente
        auctions[0] = Auction({
            seller: msg.sender,
            itemName: "Vintage Car",
            startingBid: 3 ether,
            highestBid: 0,
            highestBidder: address(0),
            active: true
        });
        auctions[1] = Auction({
            seller: msg.sender,
            itemName: "Picasso Painting",
            startingBid: 5 ether,
            highestBid: 0,
            highestBidder: address(0),
            active: true
        });
        auctions[2] = Auction({
            seller: msg.sender,
            itemName: "Special Book",
            startingBid: 1 ether,
            highestBid: 0,
            highestBidder: address(0),
            active: false
        });
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    struct Auction {
        address seller;
        string itemName;
        uint startingBid;
        uint highestBid;
        address highestBidder;
        bool active;
    }


    event AuctionCreated(
        uint indexed auctionId,
        address indexed seller,
        string itemName,
        uint startingBid
    );

    event BidPlaced(
        uint indexed auctionId,
        address indexed bidder,
        uint amount
    );

    event AuctionEnded(
        uint indexed auctionId,
        address winner,
        uint winningBid
    );

    modifier auctionExists(uint auctionId) {
        require(auctions[auctionId].seller != address(0), "Auction does not exist");
        _;
    }

    modifier onlySeller(uint auctionId) {
        require(auctions[auctionId].seller == msg.sender, "Not the seller");
        _;
    }

    modifier auctionActive(uint auctionId) {
        require(auctions[auctionId].active, "Auction is not active");
        _;
    }

    function createAuction(
        string calldata itemName,
        uint startingBid
    ) external override returns (uint auctionId) {
        auctionId = auctionCounter++;
        auctions[auctionId] = Auction({
            seller: msg.sender,
            itemName: itemName,
            startingBid: startingBid,
            highestBid: 0,
            highestBidder: address(0),
            active: true
        });

        activeAuctions.push(auctionId);

        emit AuctionCreated(auctionId, msg.sender, itemName, startingBid);
    }

    function placeBid(uint auctionId) external payable override auctionExists(auctionId) auctionActive(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(msg.value > auction.highestBid && msg.value >= auction.startingBid, "Bid is too low");

        if (auction.highestBid > 0) {
            // Reembolsar al postor anterior
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function endAuction(uint auctionId) external override auctionExists(auctionId) onlySeller(auctionId) auctionActive(auctionId) {
        Auction storage auction = auctions[auctionId];
        auction.active = false;

        if (auction.highestBid > 0) {
            payable(auction.seller).transfer(auction.highestBid);
        }
        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    function getAuctionDetails(uint auctionId)
        external
        view
        override
        auctionExists(auctionId)
        returns (
            address seller,
            string memory itemName,
            uint startingBid,
            uint highestBid,
            address highestBidder,
            bool active
        )
    {
        Auction memory auction = auctions[auctionId];
        return (
            auction.seller,
            auction.itemName,
            auction.startingBid,
            auction.highestBid,
            auction.highestBidder,
            auction.active
        );
    }

    function getActiveAuctions() external view override returns (uint[] memory auctionIds) {
        uint activeCount = 0;
        for (uint i = 0; i < activeAuctions.length; i++) {
            if (auctions[activeAuctions[i]].active) {
                activeCount++;
            }
        }

        uint[] memory activeIds = new uint[](activeCount);
        uint index = 0;
        for (uint i = 0; i < activeAuctions.length; i++) {
            if (auctions[activeAuctions[i]].active) {
                activeIds[index] = activeAuctions[i];
                index++;
            }
        }
        return activeIds;
    }
}
