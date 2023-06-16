// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Patient {
    address patientAddress;
    string uri;
    uint256[] appointments;
}
