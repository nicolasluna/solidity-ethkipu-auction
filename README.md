# Auction Smart Contract

This smart contract implements an auction system where bidders can place bids, and the highest bidder becomes the winner. The contract supports extending the auction time and provides partial refund functionality for participants.

### Contract Overview
The contract allows users to place bids, track the current highest bid, and withdraw funds after the auction has ended. It includes several key features:
- **Auction Timer**: The auction has a start and end time. If a new bid is placed within the last 10 minutes, the auction time is extended by 10 minutes.
- **Bidder Information**: Information on bidders is stored in a `mapping` and an array, allowing for efficient access to individual bids and a list of all bidders.
- **Partial Withdrawals**: Bidders can withdraw a part of their previous bid if it is above the last accepted bid.
- **Withdraw Funds**: Only the owner can withdraw funds after the auction has ended, transferring the bids (excluding the winner) minus a 2% fee.

### Functions

#### 1. **addBid()**:
- **Purpose**: Allows users to place a bid in the auction.
- **Parameters**: None (the bid amount is provided via `msg.value`).
- **Requirements**:
  - The bid must be at least 5% higher than the current winning bid.
- **Logic**:
  - If the sender is a new bidder, their data is added to the `bidders` mapping and the `allBidders` array.
  - If the sender is an existing bidder, the bid amount is updated.
  - If a new bid is placed close to the end of the auction, the auction time is extended by 10 minutes.
- **Event**: Emits `AcceptedBid(address indexed bidder, uint256 amount)`.

#### 2. **getWinnerBid()**:
- **Purpose**: Returns the current winner's address and their bid amount.
- **Parameters**: None.
- **Returns**:
  - Winner's address.
  - Winner's bid amount.
- **Requirements**: The auction must be ended (`onlyEnded` modifier).

#### 3. **endAuction()**:
- **Purpose**: Ends the auction and emits the final winner and bid amount.
- **Parameters**: None.
- **Requirements**: Only the contract owner can call this function (`onlyOwner` modifier).
- **Event**:

#### 4. **getAllBids()**:
- **Purpose**: Returns an array containing all bids placed in the auction.
- **Parameters**: None.
- **Returns**: Array of `Bidder` structs (contains bidder address, bid, and total bid).

#### 5. **withdrawBids()**:
- **Purpose**: Allows the owner to withdraw funds after the auction has ended.
- **Parameters**: None.
- **Logic**:
  - The function calculates the total amount of bids (excluding the winner).
  - It sends back the bid amount to each non-winning bidder minus a 2% fee.
- **Event**: Emits `WithdrawFunds(uint256 totalAmount, uint256 totalFees, uint256 totalAddresses)`.

#### 6. **partialWithdraw()**:
- **Purpose**: Allows bidders to withdraw part of their previous bids (i.e., the difference between the total bid and the last accepted bid).
- **Parameters**: None.
- **Requirements**: The auction must be active (`onlyActive` modifier).
- **Logic**:
  - The function ensures the sender is a valid bidder and has overpaid compared to their last accepted bid.
  - Partial withdrawal is allowed only if the remaining balance is greater than 0.
- **Event**: Emits `PartialRefund(address indexed bidder, uint256 amount)`.

#### 7. **getBalance()**:
- **Purpose**: Returns the bid and total bid amounts of the sender.
- **Parameters**: None.
- **Returns**: 
  - The sender's last placed bid amount.
  - The total bid amount.

### Events

- **AcceptedBid**: Triggered when a new bid is accepted.
  - **Parameters**:
    - `address indexed bidder`: Address of the bidder.
    - `uint256 amount`: Bid amount.

- **AuctionEnded**: Triggered when the auction ends, indicating the winning bidder.
  - **Parameters**:
    - `address indexed winnerBidder`: Address of the winning bidder.
    - `uint256 amount`: Winning bid amount.

- **WithdrawFunds**: Triggered when the contract owner withdraws the funds after the auction.
  - **Parameters**:
    - `uint256 totalAmount`: Total funds withdrawn.
    - `uint256 totalFees`: Fees deducted from the total amount.
    - `uint256 totalAddresses`: The number of bidders who received refunds.

- **PartialRefund**: Triggered when a bidder partially withdraws their funds.
  - **Parameters**:
    - `address indexed bidder`: Address of the bidder.
    - `uint256 amount`: The amount refunded.

### Modifiers

- **onlyActive**: Ensures the auction is still active (not ended).
- **onlyOwner**: Ensures the caller is the contract owner.
- **onlyEnded**: Ensures the auction has ended.

### Auction Parameters

- **startTime**: The start time of the auction, set when the contract is deployed.
- **endTime**: The end time of the auction, initially set to 10 days from the start time.
- **EXTENSION_TIME**: The time added to the auction if a bid is placed within 10 minutes of the auction's end.
- **winnerBid**: The current highest bid in the auction.
- **winnerBidder**: The address of the current highest bidder (winner).

---

