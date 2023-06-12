//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct Appointment {
    uint256 id;
    uint256 patientId;
    uint256 doctorId;
    bool completedByPatient;
    bool completedByDoctor;
    bool paymentDone;
}
