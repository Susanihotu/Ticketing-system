// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TicketingSystem} from "../src/TicketingSystem.sol";

contract TicketingSystemTest is Test {
    TicketingSystem public ticketingSystem;
    address public organizer = address(1);
    address public buyer = address(2);
    address public secondaryBuyer = address(3);

    event TicketCreated(uint256 indexed ticketId,uint256 eventId,uint256 price,address indexed owner,uint256 quantity);
    event TicketTransferred(uint256 indexed ticketId,address indexed from,address indexed to);
    event TicketForSale(uint256 indexed ticketId, uint256 price);
    event TicketVerified(uint256 indexed ticketId, address indexed verifier);

    function setUp() public {
        vm.prank(organizer);
        ticketingSystem = new TicketingSystem();
    }

    function testCreateTickets() public {
        vm.prank(organizer);
        uint256 ticketId = ticketingSystem.createTickets(1, 1 ether, 10);

        (uint256 createdTicketId, uint256 eventId, address owner, uint256 price, bool isForSale, , uint256 quantity, uint256 remainingQuantity) = ticketingSystem.tickets(ticketId);

        assertEq(createdTicketId, ticketId, "Ticket ID mismatch");
        assertEq(eventId, 1, "Event ID mismatch");
        assertEq(owner, organizer, "Owner mismatch");
        assertEq(price, 1 ether, "Price mismatch");
        assertEq(isForSale, true, "Ticket should be for sale");
        assertEq(quantity, 10, "Quantity mismatch");
        assertEq(remainingQuantity, 10, "Remaining quantity mismatch");
    }

    function testSetTicketForSale() public {
        vm.prank(organizer);
        uint256 ticketId = ticketingSystem.createTickets(1, 1 ether, 10);

        vm.prank(organizer);
        ticketingSystem.setTicketForSale(ticketId, 2 ether);

        (, , , uint256 updatedPrice, bool isForSale, , , ) = ticketingSystem.tickets(ticketId);

        assertEq(updatedPrice, 2 ether, "Updated price mismatch");
        assertTrue(isForSale, "Ticket should be for sale");
    }

    function testPurchaseTicket() public {
    vm.prank(organizer);
    uint256 ticketId = ticketingSystem.createTickets(1, 1 ether, 10);

    vm.deal(buyer, 2 ether); // Ensure buyer has enough funds
    console.log("Buyer balance before:", buyer.balance);

    // Log ticket details before purchase
    (, , address owner, uint256 price, bool isForSale, , uint256 quantity, uint256 remainingQuantity) = ticketingSystem.tickets(ticketId);
    console.log("Ticket owner:", owner);
    console.log("Ticket price:", price);
    console.log("Is for sale:", isForSale);
    console.log("Owner after primary purchase:", owner);
    console.log("Quantity:", quantity);
    console.log("Remaining quantity:", remainingQuantity);

    vm.prank(buyer);
    ticketingSystem.purchaseTicket{value: 1 ether}(ticketId);

    // Log remaining quantity after purchase
    (, , , , , , , remainingQuantity) = ticketingSystem.tickets(ticketId);
    console.log("Remaining quantity after purchase:", remainingQuantity);
}

    function testPurchaseSecondaryTicket() public {
    vm.prank(organizer);
    uint256 ticketId = ticketingSystem.createTickets(1, 1 ether, 1);

    vm.deal(buyer, 2 ether);
    vm.prank(buyer);
    ticketingSystem.purchaseTicket{value: 1 ether}(ticketId);

    (, , address primaryOwner, , , , , uint256 remainingQuantity) = ticketingSystem.tickets(ticketId);
    console.log("Primary owner:", primaryOwner);
    console.log("Remaining quantity after primary purchase:", remainingQuantity);

    vm.prank(buyer);
    ticketingSystem.listTicketForSecondarySale(ticketId, 1.5 ether);

    // Buyer lists the ticket for secondary sale
vm.prank(buyer); // Ensure this is the buyer
ticketingSystem.listTicketForSecondarySale(ticketId, 1.5 ether);


    (, , address secondaryOwner, uint256 price, bool isForSale, bool isSecondary, , ) = ticketingSystem.tickets(ticketId);
    console.log("Secondary owner:", secondaryOwner);
    console.log("Secondary price:", price);
    console.log("Is for sale:", isForSale);
    console.log("Is secondary:", isSecondary);

    vm.deal(secondaryBuyer, 2 ether);
    vm.prank(secondaryBuyer);
    ticketingSystem.purchaseSecondary{value: 1.5 ether}(ticketId);

    (, , address newOwner, , , , , ) = ticketingSystem.tickets(ticketId);
    console.log("New owner after secondary purchase:", newOwner);}

    function testListTicketForSecondarySale() public {
    // Step 1: Organizer creates a ticket
    vm.prank(organizer); // Use organizer's address
    uint256 ticketId = ticketingSystem.createTickets(1, 1 ether, 1);

    // Step 2: Buyer purchases the primary ticket
    vm.deal(buyer, 2 ether); // Provide buyer with enough funds
    vm.prank(buyer);         // Set msg.sender to buyer
    ticketingSystem.purchaseTicket{value: 1 ether}(ticketId);

    // Step 3: Buyer lists the ticket for secondary sale
    uint256 secondaryPrice = 1.5 ether;
    vm.prank(buyer);         // Set msg.sender to buyer
    ticketingSystem.listTicketForSecondarySale(ticketId, secondaryPrice);

    // Step 4: Assert the ticket is correctly listed for secondary sale
    (
        , 
        , 
        address owner, 
        uint256 price, 
        bool isForSale, 
        bool isSecondary, 
        , 
    ) = ticketingSystem.tickets(ticketId);

    assertEq(owner, buyer, "Owner mismatch after listing for secondary sale");
    assertEq(price, secondaryPrice, "Price mismatch after listing for secondary sale");
    assertTrue(isForSale, "Ticket should be for sale");
    assertTrue(isSecondary, "Ticket should be marked as secondary");
}




    function testVerifyTicket() public {
        vm.prank(organizer);
        uint256 ticketId = ticketingSystem.createTickets(1, 1 ether, 10);

        bool verified = ticketingSystem.verifyTicket(ticketId);

        assertTrue(verified, "Ticket should be verified");
    }
}
