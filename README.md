# Decentralized Online HealthCare System

This smart contract, written in Solidity and Foundry, implements a decentralized online healthcare system where doctors are registered as non-fungible tokens (NFTs) and patients can book appointments with them. The contract manages the booking process, stores patient records in encrypted form using the Lit Protocol, and provides functionality for payment and feedback.

## Contract Details

### State Variables

- `doctorsNFT`: An instance of the `Doctors` contract, used to manage the NFTs representing doctors.
- `doctors`: A mapping that associates doctor IDs with `Doctor` structs, storing information about each doctor.
- `doctorIds`: A mapping that associates doctor addresses with their corresponding IDs.
- `patients`: A mapping that associates patient IDs with `Patient` structs, storing information about each patient.
- `patientIds`: A mapping that associates patient addresses with their corresponding IDs.
- `appointments`: A mapping that associates appointment IDs with `Appointment` structs, storing information about each appointment.
- `_patientIdCounter`: A counter for assigning unique patient IDs.
- `_applicationIdCounter`: A counter for assigning unique appointment IDs.

### Events

- `NewDoctorRegistered`: Triggered when a new doctor is registered. Includes the doctor's address and URI (Uniform Resource Identifier).
- `NewPatientRegistered`: Triggered when a new patient is registered. Includes the patient's address and URI.
- `AppointmentBooked`: Triggered when an appointment is booked. Includes the appointment ID, patient ID, and doctor ID.
- `AppointmentPaid`: Triggered when an appointment payment is made. Includes the appointment ID, payment amount, patient address, and doctor address.

### Errors

- `StakeMoreToBecomeDoctor`: Throws an error if the value sent with the `addDoctor` function call is less than the required stake amount.
- `OnlyPatientCanBookAppointment`: Throws an error if the caller is not the patient who is trying to book an appointment.
- `NotEnoughFees`: Throws an error if the value sent with the `makeAppointment` function call is less than the doctor's fees.
- `AppointmentAlreadyBooked`: Throws an error if the requested appointment timeslot is already booked.
- `OnlyPatientCanGiveFeedbackOfAppointment`: Throws an error if the caller is not the patient who can give feedback for the appointment.
- `OnlyDoctorCanGiveFeedbackOfAppointment`: Throws an error if the caller is not the doctor who can give feedback for the appointment.
- `OnlyDoctorCanReceivePayment`: Throws an error if the caller is not the doctor who can receive payment for the appointment.
- `PaymentAlreadyDone`: Throws an error if the payment for the appointment has already been done.
- `PaymentFailed`: Throws an error if the payment transfer fails.
- `URICannotBeEmpty`: Throws an error if the URI provided is empty.
- `DoctorFeesCannotBeZero`: Throws an error if the doctor's fees are set to zero.

### Functions

- `makeAppointment(uint256 _patientId, uint256 _doctorId, uint256 timeslot, string memory _meetingId)`: Allows a patient to book an appointment with a doctor. Requires payment of the doctor's fees. Emits an `AppointmentBooked` event upon successful booking.
- `completeAppointmentByPatient(uint256 _appointmentId)`: Allows a patient to mark an appointment as completed from their end.
- `completeAppointmentByDoctor(uint256 _appointmentId)`: Allows a doctor to mark an appointment as completed from their end.
- `receivePaymentByDoctor(uint256 _appointmentId)`: Allows a doctor to receive payment for a completed appointment.

Emits an `AppointmentPaid` event upon successful payment.

- `addDoctor(string memory uri, uint256 _feesInWei)`: Allows a user to register as a doctor by providing a URI and staking a required amount. Emits a `NewDoctorRegistered` event upon successful registration.
- `addPatient(string memory _uri)`: Allows a user to register as a patient by providing a URI. Emits a `NewPatientRegistered` event upon successful registration.
- `canAccessPatientData(uint256 _patientId, uint256 _doctorId)`: Checks if a doctor can access a patient's data based on their appointment history.
- `getDoctorById(uint256 _id)`: Retrieves the address of a doctor based on their ID.
- `getPatientById(uint256 _id)`: Retrieves a `Patient` struct based on the patient ID.
- `getDoctorAddressById(uint256 _id)`: Retrieves the address of a doctor based on their ID.
- `getDoctorFeesById(uint256 _id)`: Retrieves the fees of a doctor based on their ID.
- `getDoctorAppointmentsById(uint256 _id, uint256 _timeslot)`: Checks if a doctor has any appointments for a specific timeslot.
- `getTotalPatients()`: Retrieves the total number of registered patients.
- `getDoctorIdByAddress(address _doctorAddress)`: Retrieves the ID of a doctor based on their address.
- `getPatientIdByAddress(address _patientAddress)`: Retrieves the ID of a patient based on their address.

## Usage

1. Deploy the smart contract.
2. Register doctors by calling the `addDoctor` function, providing the doctor's URI and staking the required amount.
3. Register patients by calling the `addPatient` function, providing the patient's URI.
4. Patients can book appointments by calling the `makeAppointment` function, providing their patient ID, the doctor's ID, the desired timeslot, and a meeting ID. The doctor's fees must be paid with the function call.
5. Patients can mark an appointment as completed by calling the `completeAppointmentByPatient` function.
6. Doctors can mark an appointment as completed by calling the `completeAppointmentByDoctor` function.
7. Doctors can receive payment for a completed appointment by calling the `receivePaymentByDoctor` function.
8. Access control functions such as `canAccessPatientData`, `getDoctorById`, `getPatientById`, etc., can be used to retrieve relevant information.
