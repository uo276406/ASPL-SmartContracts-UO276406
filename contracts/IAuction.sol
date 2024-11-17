// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuction {

    function createAuction(
        string calldata itemName,
        uint startingBid
    ) external returns (uint auctionId);

    function placeBid(uint auctionId) external payable;

    function endAuction(uint auctionId) external;

    function getAuctionDetails(uint auctionId)
        external
        view
        returns (
            address seller,
            string memory itemName,
            uint startingBid,
            uint highestBid,
            address highestBidder,
            bool active
        );

    function getActiveAuctions() external view returns (uint[] memory auctionIds);
}
