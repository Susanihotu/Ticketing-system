// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TicketingSystem {
    struct Ticket {
        uint256 ticketId;
        uint256 eventId;
        address owner;
        uint256 price;
        bool isForSale;
        bool isSecondary;
        uint256 quantity;
        uint256 remainingQuantity;
    }

    mapping(uint256 => Ticket) public tickets;
    mapping(bytes32 => bool) public ticketHashes;
    mapping(uint256 => mapping(address => bool)) public ticketPurchases;

    uint256 public ticketCounter;
    address public organizer;
    uint256 public secondaryMarketFeePercentage = 5;

    event TicketCreated(
        uint256 indexed ticketId, uint256 eventId, uint256 price, address indexed owner, uint256 quantity
    );
    event TicketTransferred(uint256 indexed ticketId, address indexed from, address indexed to);
    event TicketForSale(uint256 indexed ticketId, uint256 price);
    event TicketVerified(uint256 indexed ticketId, address indexed verifier);

    constructor() {
        organizer = msg.sender;
    }

    modifier OnlyOrganizer() {
        require(msg.sender == organizer, "NOT ORGANIZER");
        _;
    }

    modifier onlyTicketOwner(uint256 ticketId) {
        require(tickets[ticketId].owner == msg.sender, "Not ticket owner");
        _;
    }

    function createTickets(uint256 eventId, uint256 price, uint256 quantity) public OnlyOrganizer returns (uint256) {
        require(quantity > 0, "Quantity must be greater than zero");

        ticketCounter++;

        tickets[ticketCounter] = Ticket(ticketCounter, eventId, organizer, price, true, false, quantity, quantity);

        emit TicketCreated(ticketCounter, eventId, price, organizer, quantity);
        return ticketCounter;
    }

    function setTicketForSale(uint256 ticketId, uint256 price) public onlyTicketOwner(ticketId) {
        Ticket storage ticket = tickets[ticketId];
        ticket.isForSale = true;
        ticket.price = price;
        emit TicketForSale(ticketId, price);
    }

    function purchaseTicket(uint256 ticketId) public payable {
        Ticket storage ticket = tickets[ticketId];

        require(ticket.remainingQuantity > 0, "Tickets sold out");
        require(ticket.isForSale, "TICKET NOT FOR SALE");
        require(!ticketPurchases[ticketId][msg.sender], "Already purchased this ticket");
        require(msg.value >= ticket.price, "INSUFFICIENT FUNDS");

        ticketPurchases[ticketId][msg.sender] = true;
        ticket.remainingQuantity--;

        (bool success,) = ticket.owner.call{value: msg.value}("");
        require(success, "Transfer to ticket owner failed");

        ticket.owner = msg.sender; // Update ownership

        if (ticket.remainingQuantity == 0) {
            ticket.isForSale = false;
        }

        emit TicketTransferred(ticketId, ticket.owner, msg.sender);
    }

    function listTicketForSecondarySale(uint256 ticketId, uint256 price) public onlyTicketOwner(ticketId) {
        require(price > 0, "Price must be greater than zero");
        Ticket storage ticket = tickets[ticketId];
        ticket.isForSale = true;
        ticket.isSecondary = true;
        ticket.price = price;

        emit TicketForSale(ticketId, price);
    }

    function purchaseSecondary(uint256 ticketId) public payable {
        Ticket storage ticket = tickets[ticketId];

        require(ticket.isSecondary, "Not a secondary market ticket");
        require(ticket.remainingQuantity == 0, "Primary tickets still available");
        require(ticket.isForSale, "Ticket not for sale");
        require(msg.value >= ticket.price, "Insufficient funds");

        uint256 secondaryMarketFee = (ticket.price * secondaryMarketFeePercentage) / 100;
        uint256 sellerRevenue = ticket.price - secondaryMarketFee;

        address previousOwner = ticket.owner;

        // Transfer the seller's revenue
        (bool sellerSuccess,) = previousOwner.call{value: sellerRevenue}("");
        require(sellerSuccess, "Transfer to seller failed");
        (bool organizerSuccess,) = organizer.call{value: secondaryMarketFee}("");
        require(organizerSuccess, "Transfer to organizer failed");

        // Update ticket ownership and status
        ticket.owner = msg.sender;
        ticket.isForSale = false;

        emit TicketTransferred(ticketId, previousOwner, msg.sender);
    }

    function verifyTicket(uint256 ticketId) public view returns (bool) {
        Ticket storage ticket = tickets[ticketId];
        return ticket.owner != address(0);
    }
}
