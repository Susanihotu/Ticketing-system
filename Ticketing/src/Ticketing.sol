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
    }
    mapping (uint256=> Ticket) public tickets;
    mapping(uint256=> uint256) public eventTicket;

    uint256 public ticketCounter;
    address public organizer;
    uint256 public secondaryMarketFeePercentage = 5;

    event TicketCreated(uint256 indexed ticketId, uint256 eventId, uint256 price, address indexed owner);
    event TicketTransferred(uint256 indexed ticketId, address indexed from, address indexed to);
    event TicketForSale(uint256 indexed ticketId, uint256 price);
    event TicketVerified(uint256 indexed ticketId, address indexed verifier);

    constructor () {
        organizer = msg.sender;
    }
    modifier OnlyOrganizer() {
        require( msg.sender == organizer, " NOT ORGANIZER");
        _;
    }
    modifier onlyTicketOwner(uint256 ticketId) {
        require(tickets[ticketId].owner == msg.sender, "Not ticket owner");
        _;
    }

    function CreateTickect(uint256 eventId, uint256 price) public OnlyOrganizer {
        ticketCounter++;
        tickets[ticketCounter]= Ticket(ticketCounter, eventId, msg.sender, price, false,false);
        emit TicketCreated (ticketCounter, eventId, price, msg.sender);
    }
    function purchaseTicket(uint256 ticketId) public payable {
        Ticket storage ticket= tickets[ticketId];
        require( ticket.isForSale, "TICKET NOT FOR SALE");
        require(msg.value >= ticket.price, "INSUFFICIENT FUNDS");
        address previousOwner = ticket.owner;
        ticket.owner = msg.sender;
        ticket.isForSale = false;
        ticket.isSecondary = true;
        payable(previousOwner).transfer(msg.value);
        emit TicketTransferred(ticketId, previousOwner, msg.sender);

    }
    function purchaseSecondary(uint256 ticketId) public payable {
        require(verifySecondarySale(ticketId), "Secondary sale not verified");
        Ticket storage ticket = tickets[ticketId];
        
        require(msg.value >= ticket.price, "Insufficient funds");

    
        uint256 secondaryMarketFee = (ticket.price * secondaryMarketFeePercentage) / 100;
        uint256 sellerRevenue = ticket.price - secondaryMarketFee;

        
        address previousOwner = ticket.owner;
        ticket.owner = msg.sender;
        ticket.isForSale = false;

        payable(previousOwner).transfer(sellerRevenue);
        payable(organizer).transfer(secondaryMarketFee);
        emit TicketTransferred(ticketId, previousOwner, msg.sender);
    }
    function setTicketForSale(uint256 ticketId, uint256 price) public onlyTicketOwner(ticketId) {
        Ticket storage ticket = tickets[ticketId];
        ticket.isForSale = true;
        ticket.price = price;
        emit TicketForSale(ticketId, price);
    }
    function verifyTicket(uint256 ticketId) public view returns (bool) {
        Ticket storage ticket = tickets[ticketId];
        return ticket.owner != address(0); 
    }
    function verifySecondarySale(uint256 ticketId) public view returns (bool) {
        Ticket storage ticket = tickets[ticketId];
        return ticket.isSecondary && ticket.isForSale && ticket.owner != address(0);
    }



}