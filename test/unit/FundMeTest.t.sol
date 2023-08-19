// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

// What can we do to work with addressses outside our system or contract?
// 1. Unit test
//      - Testing a specific part of our code
// 2. Integration test
//      - Testing how our code works with other parts of our code
// 3. Forked Test
//      - Testing our code on a simulated real environment
// 4- Staging
//      - Testing our code in a real environment that is not production.

contract FundMETest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); // creats a fake account

    uint256 constant SEND_VALUE = 3 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    HelperConfig public helperConfig;

    // setUp() runs first before any test function

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe, helperConfig) = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // adds balance to fake account USER
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public {
        console.log("fundMe.getOwner()  ", fundMe.getOwner());
        console.log("msg.sender        ", msg.sender);
        console.log("user              ", USER);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughETH() public {
        vm.expectRevert(); // The next TX has to revert for the test to pass
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE /* = 10 * 10 ** 18 */ }();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToFundersArray() public funded {
        address newFunder = fundMe.getFunder(0);
        address[] memory funders = fundMe.getFunders();
        assertEq(funders.length, 1);
        assertEq(newFunder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); // The next TX will be sent by USER
        vm.expectRevert(); // The next TX has to revert for the test to pass
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft(); //  gas limit set 1000
        vm.txGasPrice(GAS_PRICE); // simulate a gas price of 1
        vm.prank(fundMe.getOwner()); // gas consumed = 200
        fundMe.withdraw();
        uint256 gasEnd = gasleft(); // gas left = 800
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //  tx.gasprice gives current gas price
        console.log("gasUsed", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunder() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        // Act
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            hoax(address(i), STARTING_BALANCE); // Creats a fake account (address) and then funds it with 10 ether
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }

    function testWithdrawFromMultipleFunderCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        // Act
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            hoax(address(i), STARTING_BALANCE); // Creats a fake account (address) and then funds it with 10 ether
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }
}
