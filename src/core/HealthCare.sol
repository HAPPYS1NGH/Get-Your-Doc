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
    error URICannotBeEmpty();
    error DoctorFeesCannotBeZero();

    /////////////////////////////////
    ///// State Variables ///////////
    /////////////////////////////////

    Doctors public doctorsNFT;
    mapping(uint256 id => Doctor) public doctors;
    mapping(address doctor => uint256 id) public doctorIds;
    mapping(uint256 id => Patient) public patients;
    mapping(address patient => uint256 id) public patientIds;
    mapping(uint256 id => Appointment) appointments;
    Counters.Counter private _patientIdCounter;
    Counters.Counter private _applicationIdCounter;

    /////////////////////////////////
    ///// Events ////////////////////
    /////////////////////////////////
    event NewDoctorRegistered(address doctorAddress, string uri);
    event NewPatientRegistered(address patientAddress, string uri);
    event AppointmentBooked(uint256 appointmentId, uint256 patientId, uint256 doctorId);
    event AppointmentPaid(uint256 appointmentId, uint256 amount, address patientAddress, address doctorAddress);

    /////////////////////////////////
    ///// Constructor ///////////////
    /////////////////////////////////

    constructor() {
        doctorsNFT = new Doctors();
    }

    function makeAppointment(uint256 _patientId, uint256 _doctorId, uint256 timeslot, string memory _meetingId)
        public
        payable
    {
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
            Appointment(currentApplicationId, _patientId, _doctorId, false, false, false, _meetingId);
        patient.appointments.push(currentApplicationId);
        emit AppointmentBooked(currentApplicationId, _patientId, _doctorId);
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

    function receivePaymentByDoctor(uint256 _appointmentId) public payable {
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
        emit AppointmentPaid(
            _appointmentId,
            doctors[appointment.doctorId].feesInWei,
            patients[appointment.patientId].patientAddress,
            _doctorAddress
        );
    }

    function addDoctor(string memory uri, uint256 _feesInWei) public payable {
        if (msg.value < 0.1 ether) {
            revert StakeMoreToBecomeDoctor(msg.value, 0.1 ether);
        }
        if (bytes(uri).length == 0) {
            revert URICannotBeEmpty();
        }
        if (_feesInWei == 0) {
            revert DoctorFeesCannotBeZero();
        }
        uint256 doctorId = doctorsNFT.safeMint(msg.sender, uri);
        Doctor storage doc = doctors[doctorId];
        doc.doctorAddress = msg.sender;
        doc.feesInWei = _feesInWei;
        doctorIds[msg.sender] = doctorId;
        emit NewDoctorRegistered(msg.sender, uri);
    }

    function addPatient(string memory _uri) public {
        if (bytes(_uri).length == 0) {
            revert URICannotBeEmpty();
        }
        uint256 currentPatientId = _patientIdCounter.current();
        _patientIdCounter.increment();
        patients[currentPatientId] = Patient(msg.sender, _uri, new uint256[](0));
        patientIds[msg.sender] = currentPatientId;
        emit NewPatientRegistered(msg.sender, _uri);
    }

    function canAccessPatientData(uint256 _patientId, uint256 _doctorId) public view returns (bool) {
        Patient memory patient = patients[_patientId];
        Doctor storage doctor = doctors[_doctorId];
        if (doctor.doctorAddress != msg.sender) {
            return false;
        }
        for (uint256 i = 0; i < patient.appointments.length; i++) {
            Appointment memory appointment = appointments[patient.appointments[i]];
            if (appointment.patientId == _patientId && appointment.doctorId == _doctorId) {
                return true;
            }
        }
        return false;
    }

    function getDoctorById(uint256 _id) public view returns (address) {
        return doctorsNFT.ownerOf(_id);
    }

    function getPatientById(uint256 _id) public view returns (Patient memory) {
        return patients[_id];
    }

    function getDoctorAddressById(uint256 _id) public view returns (address) {
        return doctors[_id].doctorAddress;
    }

    function getDoctorFeesById(uint256 _id) public view returns (uint256) {
        return doctors[_id].feesInWei;
    }

    function getDoctorAppointmentsById(uint256 _id, uint256 _timeslot) public view returns (bool) {
        return doctors[_id].appointments[_timeslot];
    }

    function getTotalPatients() public view returns (uint256) {
        return _patientIdCounter.current();
    }

    function getDoctorIdByAddress(address _doctorAddress) public view returns (uint256) {
        return doctorIds[_doctorAddress];
    }

    function getPatientIdByAddress(address _patientAddress) public view returns (uint256) {
        return patientIds[_patientAddress];
    }
}
