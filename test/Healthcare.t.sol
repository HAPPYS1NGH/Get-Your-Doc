// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/core/HealthCare.sol";

contract DoctorTest is Test {
    HealthCare hc;
    address doctor1 = address(0x1);
    address patient1 = address(0x2);
    address address3 = address(0x3);

    function setUp() public {
        hc = new HealthCare();
    }

    function test_AddPatient() public {
        hoax(patient1);
        hc.addPatient("uri");
        Patient memory patient = hc.getPatientById(0);
        assertEq(patient.patientAddress, patient1);
        assertEq(patient.uri, "uri");
        assertEq(patient.appointments.length, 0);
        vm.stopPrank();
    }

    function test_AddDoctorWithoutStaking() public payable {
        hoax(doctor1);
        vm.expectRevert();
        hc.addDoctor("uri", 10000000);
        vm.stopPrank();
    }

    function test_AddDoctor(uint256 timeslot) public payable {
        hoax(doctor1);
        hc.addDoctor{value: 0.1 ether}("uri", 10000000);
        address addressOfDocNFT = hc.getDoctorById(0);
        address addressOfDocStruct = hc.getDoctorAddressById(0);
        bool availableSlot = hc.getDoctorAppointmentsById(0, timeslot);
        assertEq(addressOfDocNFT, doctor1);
        assertEq(addressOfDocStruct, doctor1);
        assertEq(availableSlot, false);
        vm.stopPrank();
    }

    function test_MakeAppointment() public payable {
        addPatient();
        addDoctor();
        hoax(patient1);
        hc.makeAppointment{value: 10000000}(0, 0, 1686631463);
    }

    function addPatient() internal {
        hoax(patient1);
        hc.addPatient("uri");
        vm.stopPrank();
    }

    function addDoctor() internal {
        hoax(doctor1);
        hc.addDoctor{value: 0.1 ether}("uri", 10000000);
        vm.stopPrank();
    }
}
