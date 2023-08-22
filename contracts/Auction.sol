pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    error auction_start_error(uint256 is_started);
    error ending_price_isless(uint256 ending_price);
    error auction_create_error(uint256 totalTime_period);
    error totalTime_period_error(uint256 totalTime_period);
    error bid_error(uint256 highest_bid);
    error zero_address_error(address contract_caller_address);

contract NFT_Auction is Ownable, Pausable, ReentrancyGuard {

    struct Auction {

        bool isERC721;
        uint256 starts_at;
        uint256 ends_at;
        uint256 current_bid;
        uint256 ending_price;
        uint256 highest_bid;
        address winner;
        address highest_bidder;
    }

    address public NFT_Creator;

    uint256 private constant time_period = 15 days;
    address public immutable seller;
    IERC721 public immutable token_address;
    uint256 public immutable token_id;

    uint256 public immutable starting_price = 0.5;
    bool public cancel;
    bool public is_started;
    bool public is_ended;

    mapping(address => uint256) bids_by_users;
    mapping(uint256 => Auction) Auction_by_token_id;

    constructor(

        address token_address,
        uint256 token_id,
        uint256 starting_price
    ){
        seller = payable(msg.sender);
        uint256 highest_bid = starting_price;
        uint256 starts_at = block.timestamp;
        uint256 ends_at = block.timestamp + time_period;
        uint256 totalTime_period = starts_at + time_period; // Total time period of Auction

        token_address = IERC721(token_address);
        token_id = token_id;
    }

    function auction_start() internal {

        require(seller != address(0), " Owner can not be a zero address");
        require(!is_started, "auction already started");

        if (block.timestamp < starts_at)
            revert auction_start_error(starts_at);

        is_started = true;
        emit Auction_start();
    }

    function auction_create(

        address token_address,
        uint256 token_id,
        uint256 starting_price,
        uint256 ending_price

    ) external {

        // Check whether Auction is still running or not

        if (block.timestamp > totalTime_period)
            revert auction_create_error(totalTime_period);

        address NFTOwner = token_address.Ownerof(token_id);

        require(msg.sender == seller || msg.sender == owner() || msg.sender == NFTOwner, "You are not Authorized");

        if (starting_price > ending_price)
            revert ending_price_isless(ending_price);

        if (totalTime_period < 1 minutes)
            revert Time_period_error(time_period);

        Auction memory auction = Auction(
            uint256(starting_price),
            uint256(ending_price),
            uint256(totalTime_period),
            address(seller),
            uint256(starts_at),
            uint256(ends_at)
        );

        Auction_by_token_id[token_id] = auction;

        emit Auction_create(
            uint256(token_id),
            address(token_address),
            uint256(auction.totalTime_period),
            uint256(auction.starting_price)
        );
    }

    function Bid(
        address token_address,
        uint256 token_id
    )
    public nonReentrant payable {
        Auction storage auction = Auction_by_token_id[token_id];
        if (block.timestamp > totalTime_period)
            revert totalTime_period_error(totalTime_period);
        uint256 new_bid = msg.value; // new bid by user
        if (msg.value == 0 || msg.sender == address(0))
            throw;
        require(msg.value > highest_bid, "bid value must be greater than highest bid");
        if (new_bid > highest_bid)
        {
            bids_by_users[msg.sender] = new_bid;
            auction.highest_bid = new_bid; //Highest bid changed
            auction.highest_bidder = msg.sender; //Highest bidder updated
            Auction_by_token_id[token_id] = auction.highest_bid;
        }
        emit Bid_changed(token_id, new_bid, msg.sender);
        emit Highest_bid_changed(msg.value, msg.sender);
    }

    function auction_cancel(
        address token_address,
        uint256 token_id
    ) public payable whenNotPaused nonReentrant {
        Auction storage auction = Auction_by_token_id[token_id];

        if (block.timestamp > totalTime_period)
            revert totalTime_period_error(totalTime_period);

        if (msg.sender == seller || msg.sender != address(0))
        {
            cancel = true;
        }

        else
        {
            console.log("Only authorized account is allowed to cancel the Auction");
        }

        // After cancelling an auction transfer the Assests
        if (auction.highest_bid > 0)
        {
            transfer(auction.highest_bidder, auction.highest_bid);
        }

        token_address.safetransfer(address(this), seller, token_id); //transfer the NFT to the Owner itself

        if (cancel)
        {
            console.log("Auction is successfully cancelled");
        }

        emit Auction_cancelled(token_id);

    }

    function auction_settle(

        address token_address,
        uint256 token_id

    ) public payable
    {
        Auction storage auction = Auction_by_token_id[token_address];

        if (block.timestamp < total_Timeperiod)
            revert totalTime_period_error(total_Timeperiod);

        if (msg.sender == seller && msg.sender != address(0)) {

            token_address.transfer(address(this), auction.highest_bidder, token_id); //Transfer the NFT to the address with highest bid

        }

        auction.winner = auction.highest_bidder;

        delete Auction_by_token_id[token_id];

        emit Auction_settlement(

            highest_bidder,
            token_id,
            auction.highest_bidder
        );

    }

    function buy(

        uint256 token_id,
        address token_address,
        address seller
    )
    public payable {

        Auction storage auction = Auction_by_token_id[token_id];

        if (msg.sender == address(0))
            revert zero_address_error(msg.sender);

        if (block.timestamp > totalTime_period)
            revert totalTime_period_error(totalTime_period);

        uint256 get_highestprice = bids_buy_users[auction.highest_bid];

        require(msg.value >= get_highest_price, "Pay the required amount to buy the NFT");

        token_address.safeTransfrom(seller, msg.sender, token_id);
        ETH_difference = get_highestprice - msg.value;

        if (msg.value > get_highest_price)
        {
            transfer(msg.sender, ETH_difference);
        }

        selfdestruct(seller);
    }

    function Auction_end(

        address token_address,
        uint256 token_id

    ) internal
    {
        require(is_ended, "Auction is not ended");

        require(msg.sender == seller || msg.sender != address(0), "Not an authorized user");

        auction.winner = auction.highest_bidder;

        emit Auction_finish(
            auction.winner,
            highest_bid
        );

    }

    /*-------------  Events  -------------*/

    event Auction_start();

    event Auction_create(
        uint256 token_id,
        address token_address,
        uint256 totalTime_period,
        uint256 starting_price
    );

    event Bid_changed(
        uint256 token_id,
        uint256 new_bid,
        address new_bidder
    );

    event Highest_bid_changed(

        address highest_bid,
        uint256 highest_bidder
    );

    event Auction_settlement(
        uint256 token_id,
        address highest_bidder,
        uint256 highest_bid
    );

    event Auction_cancelled(uint256 token_id);

    event Auction_finish(
        address winner,
        uint256 highest_bid
    );

}