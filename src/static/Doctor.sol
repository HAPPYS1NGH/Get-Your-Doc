//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct Doctor {
    address doctorAddress;
    uint256 feesInWei;
    mapping(uint256 timeslot => bool available) appointments;
}
