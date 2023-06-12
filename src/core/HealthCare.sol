//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../utils/Doctors.sol";
import "../static/Patient.sol";
import "../static/Doctor.sol";
import "../static/Appointment.sol";

//// @title Decentralised Online HealthCare System
/// @author Harpreet Singh
/// @notice This contract is used to manage the healthcare system where the doctors are registered as NFTs and Patient can book their slot according to their availability. The reocrds of the patient are stored in encrypted form using Lit Protocol and given access to the doctor when the patient books an appointment

contract HealthCare {
    using Counters for Counters.Counter;

    //////////////////////////////
    //// Errors //////////////////
    //////////////////////////////
    error StakeMoreToBecomeDoctor(uint256 amount, uint256 requiredAmount);
    error OnlyPatientCanBookAppointment(address defaulter, address patientAddress);
    error NotEnoughFees(uint256 amount, uint256 fees);
    error AppointmentAlreadyBooked(uint256 timeslot);
    error OnlyPatientCanGiveFeedbackOfAppointment(address defaulter, address patientAddress);
    error OnlyDoctorCanGiveFeedbackOfAppointment(address defaulter, address doctorAddress);
    error OnlyDoctorCanReceivePayment(address defaulter, address doctorAddress);
    error PaymentAlreadyDone(uint256 appointmentId);
    error PaymentFailed();

    /////////////////////////////////
    ///// State Variables ///////////
    /////////////////////////////////

    Doctors public doctorsNFT;
    mapping(uint256 id => Doctor) public doctors;
    mapping(uint256 id => Patient) public patients;
    mapping(uint256 id => Appointment) appointments;
    // mapping(address patient => mapping(uint256 apponitmentId => address doctor)) private appointments;
    Counters.Counter private _patientIdCounter;
    Counters.Counter private _applicationIdCounter;

    /////////////////////////////////
    ///// Events ////////////////////
    /////////////////////////////////
    event NewDoctorRegistered(address doctorAddress, string uri);
    event NewPatientRegistered(address patientAddress, string name, string uri);

    /////////////////////////////////
    ///// Constructor ///////////////
    /////////////////////////////////

    constructor() {
        doctorsNFT = new Doctors();
    }

    function makeAppointment(uint256 _patientId, uint256 _doctorId, uint256 timeslot) public payable {
        Patient storage patient = patients[_patientId];
        if (patient.patientAddress != msg.sender) {
            revert OnlyPatientCanBookAppointment(msg.sender, patient.patientAddress);
        }
        Doctor storage doc = doctors[_doctorId];
        if (msg.value < doc.feesInWei) {
            revert NotEnoughFees(msg.value, doc.feesInWei);
        }
        if (doc.appointments[timeslot] == true) {
            revert AppointmentAlreadyBooked(timeslot);
        }
        doc.appointments[timeslot] = true;

        uint256 currentApplicationId = _applicationIdCounter.current();
        _applicationIdCounter.increment();
        appointments[currentApplicationId] =
            Appointment(currentApplicationId, _patientId, _doctorId, false, false, false);
        patient.appointments.push(currentApplicationId);
    }

    function completeAppointmentByPatient(uint256 _appointmentId) public {
        Appointment storage appointment = appointments[_appointmentId];
        if (patients[appointment.patientId].patientAddress != msg.sender) {
            revert OnlyPatientCanGiveFeedbackOfAppointment(msg.sender, patients[appointment.patientId].patientAddress);
        }
        appointment.completedByPatient = true;
    }

    function completeAppointmentByDoctor(uint256 _appointmentId) public {
        Appointment storage appointment = appointments[_appointmentId];
        if (getDoctorById(appointment.doctorId) != msg.sender) {
            revert OnlyDoctorCanGiveFeedbackOfAppointment(msg.sender, doctors[appointment.patientId].doctorAddress);
        }
        appointment.completedByPatient = true;
    }

    function receivePayment(uint256 _appointmentId) public payable {
        Appointment storage appointment = appointments[_appointmentId];
        if (appointment.paymentDone == true) {
            revert PaymentAlreadyDone(_appointmentId);
        }
        address _doctorAddress = getDoctorById(appointment.doctorId);
        if (_doctorAddress != msg.sender) {
            revert OnlyDoctorCanReceivePayment(msg.sender, _doctorAddress);
        }
        appointment.paymentDone = true;
        (bool sent,) = payable(_doctorAddress).call{value: doctors[appointment.doctorId].feesInWei}("");
        if (!sent) {
            revert PaymentFailed();
        }
    }

    function addDoctor(string memory uri, uint256 _feesInWei) public payable {
        if (msg.value < 0.1 ether) {
            revert StakeMoreToBecomeDoctor(msg.value, 0.1 ether);
        }
        uint256 doctorId = doctorsNFT.safeMint(msg.sender, uri);
        Doctor storage doc = doctors[doctorId];
        doc.doctorAddress = msg.sender;
        doc.feesInWei = _feesInWei;
        emit NewDoctorRegistered(msg.sender, uri);
    }

    function addPatient(string memory _name, string memory _uri) public {
        uint256 currentPatientId = _patientIdCounter.current();
        _patientIdCounter.increment();
        patients[currentPatientId] = Patient(currentPatientId, msg.sender, _name, _uri, new uint256[](0));
        emit NewPatientRegistered(msg.sender, _name, _uri);
    }

    function getDoctorById(uint256 _id) public view returns (address) {
        return doctorsNFT.ownerOf(_id);
    }

    function getPatientById(uint256 _id) public view returns (Patient memory) {
        return patients[_id];
    }
}
