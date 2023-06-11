//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../utils/Doctors.sol";
import "../static/Patient.sol";

contract HealthCare {
    using Counters for Counters.Counter;

    ///////////////////////
    //// Errors ///////////
    ///////////////////////
    error StakeMoreToBecomeDoctor(uint256 amount);

    /////////////////////////////////
    //////// State Variables ////////
    /////////////////////////////////

    Doctors public doctors;
    mapping(uint256 id => Patient) public patients;
    Counters.Counter private _patientIdCounter;

    /////////////////////////////////
    ///// Events ////////////////////
    /////////////////////////////////
    event NewDoctorRegistered(address doctorAddress, string uri);

    /////////////////////////////////
    ///// Constructor ///////////////
    /////////////////////////////////

    constructor() {
        doctors = new Doctors();
    }

    function addDoctor(string memory uri) public payable {
        if (msg.value < 0.1 ether) {
            revert StakeMoreToBecomeDoctor(msg.value);
        }
        doctors.safeMint(msg.sender, uri);
        emit NewDoctorRegistered(msg.sender, uri);
    }

    function addPatient(string memory _name, string memory _uri) public {
        uint256 currentId = _patientIdCounter.current();
        _patientIdCounter.increment();
        patients[currentId] = Patient(currentId, msg.sender, _name, _uri);
    }

    function getDoctorByID(uint256 _id) public view returns (address) {
        return doctors.ownerOf(_id);
    }

    function getPatientById(uint256 _id) public view returns (Patient memory) {
        return patients[_id];
    }
}
