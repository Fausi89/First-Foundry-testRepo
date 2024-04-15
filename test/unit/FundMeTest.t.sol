//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol"; // we could use console funcitons later
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe; // make it a storage variable

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000 wei
    uint256 constant STARTING_BALANCE = 1000 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // us -> FundMeTest -> deploying FundMe, so owner of FundMe is now FundMeTest contract
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // deal 1000 ether to USER
    }   // setUp always runs first


    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender () public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // expect a revert, we are telling the VM to expect a revert
        fundMe.fund(); // send value 0 or less than 5 usD as we set minimum

    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
         // Implement the logic to retrieve the amount funded for a specific address
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // arrange, act, assert methodology
        // arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        uint256 gasStart = gasleft(); // gasleft() is built-in in Solidity
        vm.txGasPrice(GAS_PRICE); // we are simulating gas fee
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // gasprice is built-in in Solidity
        console.log("Gas used: ", gasUsed); // we can use console.log to see the gas used

        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we are starting with index 1 because with 0 sometimes we get revert
            for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // hoax does prank and deal at same time
            // we can populat the address as address(0) or address(1) etc. and they must be uint160 as they have same amount of bytes as an address
            // from Solidity 0.8. we can no longer cast explicity from address to uint256, we have to use address type uint160
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            // fund the fundMe

            }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // vm.prank(fundMe.getOwner()); but we will use this syntax with start and stop
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0); // removed all the funds
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance); 
        // owner got all the funds, but we see no gas fee was abducted because when we work with Anvil gas fee defaults to 0
        // if we want to simulate gas fee, we can use the txGasPrice function
        }

        function testCheaperWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we are starting with index 1 because with 0 sometimes we get revert
            for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // hoax does prank and deal at same time
            // we can populat the address as address(0) or address(1) etc. and they must be uint160 as they have same amount of bytes as an address
            // from Solidity 0.8. we can no longer cast explicity from address to uint256, we have to use address type uint160
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            // fund the fundMe

            }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // vm.prank(fundMe.getOwner()); but we will use this syntax with start and stop
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0); // removed all the funds
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance); 
        // owner got all the funds, but we see no gas fee was abducted because when we work with Anvil gas fee defaults to 0
        // if we want to simulate gas fee, we can use the txGasPrice function
        }
}