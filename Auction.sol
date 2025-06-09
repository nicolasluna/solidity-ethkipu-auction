// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract Auction {

    // contract owner
    address private owner;
    // best bid address
    address payable private winnerBidder;
    // best bid placed
    uint256 private winnerBid;
    // auction start time
    uint256 private startTime;
    // auction end time
    uint256 private endTime;
    // auction extension time before end
    uint256 constant private EXTENSION_TIME = 10 minutes;

    // for each new Bid: address, bid amount and total bid amount (acumulated)
    struct Bidder {
        address payable bidder;
        uint256 bid;
        uint256 totalBid;
    }

    // mapping address with Bidder struct
    mapping(address => Bidder) private bidders;
    // array all bidders struct
    Bidder[] private allBidders;
    // store index to sincronize bidders mapping and allBidders array
    mapping(address => uint256) private bidderIndex;

    // accpeted bid event 
    event AcceptedBid(address indexed bidder, uint256 amount);
    // auction ended event
    event AuctionEnded(address indexed winnerBidder, uint256 amount);
    // final funds withdraw
    event WithdrawFunds(uint256 totalAmount, uint256 totalFees, uint256 totalAddresses);
    // partial funds withdraw
    event PartialWithdraw(address indexed bidder, uint256 amount);

    // initialize values
    constructor() {
        startTime = block.timestamp; // starts now
        endTime = block.timestamp + 10 days; // now + 10 days
        winnerBid = 100 wei; // initial bid amount
        owner = msg.sender; // contract owner
    }

    // ensures the auction is still active
    modifier onlyActive() {
        require (block.timestamp < endTime, "Auction was ended");
        _;
    }

    // ensures the caller is the contract owner
    modifier onlyOwner() {
        require (msg.sender == owner, "Only contract owner");
        _; 
    }

    // ensures the auction has ended.
    modifier onlyEnded() {
        require (block.timestamp >= endTime, "Auction is not ended");
        _; 
    }

    // allow users to place a bid in the auction
    function addBid() external payable onlyActive {
        uint256 newBid = msg.value;
        address bidAddress = msg.sender;
        require(newBid >= winnerBid * 105 / 100, "Bid must be at least 5% greater than current winner");
        Bidder storage bid = bidders[bidAddress];

        if (bid.bidder == address(0)) {
            // new address bid
            Bidder memory newBidder = Bidder({
                bidder: payable(bidAddress),
                bid: newBid,
                totalBid: newBid
            });

            // add to mapping and array struct
            bidders[bidAddress] = newBidder;
            allBidders.push(newBidder);
            // store index
            bidderIndex[bidAddress] = allBidders.length;
        } else {
            // existing address
            bid.bid = newBid;
            bid.totalBid += newBid;

            // update allBidders
            uint256 index = bidderIndex[bidAddress] - 1;
            allBidders[index].bid = newBid;
            allBidders[index].totalBid += newBid;
        }

        // current winner bid
        winnerBid = newBid;
        winnerBidder = payable(bidAddress);
        emit AcceptedBid(bidAddress, newBid);

        // Extend auction end time
        if (block.timestamp > (endTime - 10 minutes)) {
            endTime += EXTENSION_TIME;
        }
    }
    
    // current winner's address and their bid amount
    function getWinnerBid() view external onlyEnded returns (address, uint256) {
        return (winnerBidder, winnerBid);
    }

    // emits the final winner and bid amount
    function endAuction() external onlyOwner onlyEnded {
        emit AuctionEnded(winnerBidder, winnerBid);
    }

    // returns all bids placed in the auction
    function getAllBids () view external returns(Bidder[] memory) {
        return allBidders;
    }

    // withdraw funds after the auction has ended
    function withdrawBids() external onlyOwner onlyEnded {
        uint256 length = allBidders.length;
        uint256 totalAmount;
        uint256 totalAmountFees;
        uint256 totalAddresses;

        // iterate all bidders
        for (uint256 i = 0; i < length; i++)  {
            uint256 totalBid = allBidders[i].totalBid;
            // exclude winner address
            if (allBidders[i].bidder != winnerBidder && totalBid > 0) {
                totalAmount += totalBid; 
                totalAddresses++;

                // transfer with 2% fee
                payable(allBidders[i].bidder).transfer(totalBid * 98/100);
                allBidders[i].totalBid = 0;
            }
        }
        totalAmountFees = totalAmount - (totalAmount * 98/100);
        emit WithdrawFunds(totalAmount, totalAmountFees, totalAddresses);
    }

    // bidder partial withdraw of their previous bids
    function partialWithdraw() external onlyActive { 
        address withdrawAddress = msg.sender;     
        require(bidders[withdrawAddress].bidder != address(0), "Invalid address to do a partial refund");       

        uint256 amountToWithdraw = bidders[withdrawAddress].totalBid - bidders[withdrawAddress].bid;
        require(amountToWithdraw > 0, "Total bid - last accepted bid must be greather than 0");       
        
        if (amountToWithdraw > 0) {
            payable(withdrawAddress).transfer(amountToWithdraw);
            bidders[withdrawAddress].totalBid = bidders[withdrawAddress].bid;
            emit PartialWithdraw(withdrawAddress, amountToWithdraw);
        }
    }

    // returns the bid and total bid amount of the sender (helper balance function)
    function getBalance() external view returns (uint256, uint256) {
        return (bidders[msg.sender].bid, bidders[msg.sender].totalBid);
    }

}
