import { LightningElement, track } from 'lwc';
import searchPatients from '@salesforce/apex/NewAppointmentController.searchPatients';
import searchDoctors from '@salesforce/apex/NewAppointmentController.searchDoctors';
import getServices from '@salesforce/apex/NewAppointmentController.getServices';
import getReasonsForVisit from '@salesforce/apex/NewAppointmentController.getReasonsForVisit';
import createAppointment from '@salesforce/apex/NewAppointmentController.createAppointment';
import checkAppointmentAvailability from '@salesforce/apex/NewAppointmentController.checkAppointmentAvailability';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NewAppointmentForm extends LightningElement {
    // Form Fields
    @track patientInput = '';
    @track selectedPatientId = '';
    @track selectedPatientLabel = '';
    @track doctorInput = '';
    @track selectedDoctorId = '';
    @track selectedDoctorLabel = '';
    @track appointmentDateTime = '';
    @track selectedServiceId = '';
    @track selectedReason = '';

    // Options for Autocomplete and Picklists
    @track patientOptions = [];
    @track doctorOptions = [];
    @track serviceOptions = [];
    @track reasonOptions = [];

    // Loading States
    @track isPatientLoading = false;
    @track isDoctorLoading = false;
    @track isServiceLoading = false;
    @track isReasonLoading = false;

    // Debounce Timers
    patientDebounceTimer;
    doctorDebounceTimer;

    // Error Message for Appointment Time
    @track appointmentTimeError = '';

    // Minimum DateTime (current date & time)
    get minDateTime() {
        const now = new Date();
        const tzOffset = now.getTimezoneOffset() * 60000; // in milliseconds
        const localISOTime = new Date(now - tzOffset).toISOString().slice(0,16);
        return localISOTime;
    }

    connectedCallback() {
        this.fetchServices();
        this.fetchReasonsForVisit();
    }

    // Fetch Services for Service Picklist
    fetchServices() {
        this.isServiceLoading = true;
        getServices()
            .then(result => {
                this.serviceOptions = result.map(service => ({
                    label: service.label,
                    value: service.value
                }));
                this.isServiceLoading = false;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isServiceLoading = false;
            });
    }

    // Fetch Reasons for Visit Picklist
    fetchReasonsForVisit() {
        this.isReasonLoading = true;
        getReasonsForVisit()
            .then(result => {
                this.reasonOptions = result.map(reason => ({
                    label: reason.label,
                    value: reason.value // Use reason.value instead of reason.label
                }));
                this.isReasonLoading = false;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isReasonLoading = false;
            });
    }

    // Handle Patient Input Change
    handlePatientInputChange(event) {
        this.patientInput = event.target.value;
        this.selectedPatientId = '';
        this.selectedPatientLabel = '';
        this.patientOptions = [];
    }

    // Handle Patient Input Key Up with Debounce
    handlePatientInputKeyUp(event) {
        clearTimeout(this.patientDebounceTimer);
        const searchTerm = this.patientInput.trim();
        if (searchTerm.length >= 3) { // Start searching after 3 characters
            this.patientDebounceTimer = setTimeout(() => {
                this.isPatientLoading = true;
                searchPatients({ searchTerm })
                    .then(result => {
                        this.patientOptions = result.map(patient => ({
                            label: patient.label,
                            value: patient.value
                        }));
                        this.isPatientLoading = false;
                    })
                    .catch(error => {
                        this.showToast('Error', error.body.message, 'error');
                        this.isPatientLoading = false;
                    });
            }, 300); // 300ms debounce
        } else {
            this.patientOptions = [];
            this.selectedPatientId = '';
            this.selectedPatientLabel = '';
        }
    }

    // Handle Patient Selection
    handlePatientSelect(event) {
        this.selectedPatientId = event.detail.value;
        // Set selectedPatientLabel based on selection for display
        const selectedOption = this.patientOptions.find(option => option.value === this.selectedPatientId);
        if(selectedOption) {
            this.selectedPatientLabel = selectedOption.label;
            this.patientInput = ''; // Clear the input field
            this.patientOptions = []; // Clear options after selection
        }
    }

    // Handle Doctor Input Change
    handleDoctorInputChange(event) {
        this.doctorInput = event.target.value;
        this.selectedDoctorId = '';
        this.selectedDoctorLabel = '';
        this.doctorOptions = [];
    }

    // Handle Doctor Input Key Up with Debounce
    handleDoctorInputKeyUp(event) {
        clearTimeout(this.doctorDebounceTimer);
        const searchTerm = this.doctorInput.trim();
        if (searchTerm.length >= 2) { // Start searching after 2 characters
            this.doctorDebounceTimer = setTimeout(() => {
                this.isDoctorLoading = true;
                searchDoctors({ searchTerm })
                    .then(result => {
                        this.doctorOptions = result.map(doctor => ({
                            label: doctor.label,
                            value: doctor.value
                        }));
                        this.isDoctorLoading = false;
                    })
                    .catch(error => {
                        this.showToast('Error', error.body.message, 'error');
                        this.isDoctorLoading = false;
                    });
            }, 300); // 300ms debounce
        } else {
            this.doctorOptions = [];
            this.selectedDoctorId = '';
            this.selectedDoctorLabel = '';
        }
    }

    // Handle Doctor Selection
    handleDoctorSelect(event) {
        this.selectedDoctorId = event.detail.value;
        // Set selectedDoctorLabel based on selection for display
        const selectedOption = this.doctorOptions.find(option => option.value === this.selectedDoctorId);
        if(selectedOption) {
            this.selectedDoctorLabel = selectedOption.label;
            this.doctorInput = ''; // Clear the input field
            this.doctorOptions = []; // Clear options after selection
        }
    }

    // Handle Appointment Date & Time Change
    handleAppointmentDateTimeChange(event) {
        this.appointmentDateTime = event.target.value;
        this.validateAppointmentTime();
    }

    // Handle Service Change
    handleServiceChange(event) {
        this.selectedServiceId = event.detail.value;
    }

    // Handle Reason for Visit Change
    handleReasonChange(event) {
        this.selectedReason = event.detail.value;
    }

    // Handle Form Submission
    handleSubmit() {
        if (this.isFormValid()) {
            // Before creating the appointment, check for availability
            checkAppointmentAvailability({
                doctorId: this.selectedDoctorId,
                appointmentDateTimeStr: this.convertToGMT(this.appointmentDateTime)
            })
            .then(isAvailable => {
                if (isAvailable) {
                    // Proceed to create the appointment
                    createAppointment({
                        patientId: this.selectedPatientId,
                        doctorId: this.selectedDoctorId,
                        appointmentDateTimeStr: this.convertToGMT(this.appointmentDateTime),
                        serviceId: this.selectedServiceId,
                        reasonForVisit: this.selectedReason
                    })
                    .then(() => {
                        this.showToast('Success', 'Appointment created successfully.', 'success');
                        this.resetForm();
                    })
                    .catch(error => {
                        this.showToast('Error', error.body.message, 'error');
                    });
                } else {
                    this.showToast('Error', 'The selected time slot is no longer available.', 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while checking appointment availability: ' + error.body.message, 'error');
            });
        }
    }

    // Handle Reset Button Click
    handleReset() {
        this.resetForm();
    }

    // Convert Local DateTime to GMT String in 'YYYY-MM-DD HH:mm:ss' format
    convertToGMT(localDateTimeStr) {
        const localDate = new Date(localDateTimeStr);
        const year = localDate.getUTCFullYear();
        const month = ('0' + (localDate.getUTCMonth() + 1)).slice(-2);
        const day = ('0' + localDate.getUTCDate()).slice(-2);
        const hours = ('0' + localDate.getUTCHours()).slice(-2);
        const minutes = ('0' + localDate.getUTCMinutes()).slice(-2);
        const seconds = ('0' + localDate.getUTCSeconds()).slice(-2);
        return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    }

    // Validate Form Fields
    isFormValid() {
        const inputs = [...this.template.querySelectorAll('lightning-input, lightning-combobox')];
        let isValid = true;
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });
        if (!this.selectedPatientId) {
            this.showToast('Error', 'Please select a patient from the list.', 'error');
            isValid = false;
        }
        if (!this.selectedDoctorId) {
            this.showToast('Error', 'Please select a doctor from the list.', 'error');
            isValid = false;
        }
        if (!this.appointmentDateTime) {
            this.showToast('Error', 'Please select an appointment date and time.', 'error');
            isValid = false;
        }
        if (this.appointmentTimeError) {
            this.showToast('Error', this.appointmentTimeError, 'error');
            isValid = false;
        }
        if (!this.selectedServiceId) {
            this.showToast('Error', 'Please select a service.', 'error');
            isValid = false;
        }
        if (!this.selectedReason) {
            this.showToast('Error', 'Please select a reason for visit.', 'error');
            isValid = false;
        }
        return isValid;
    }

    // Reset Form Fields
    resetForm() {
        this.patientInput = '';
        this.selectedPatientId = '';
        this.selectedPatientLabel = '';
        this.doctorInput = '';
        this.selectedDoctorId = '';
        this.selectedDoctorLabel = '';
        this.appointmentDateTime = '';
        this.selectedServiceId = '';
        this.selectedReason = '';
        this.patientOptions = [];
        this.doctorOptions = [];
        this.appointmentTimeError = '';
    }

    // Show Toast Notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }

    // Validate Appointment Time (9 AM - 5 PM GMT)
    validateAppointmentTime() {
        if (!this.appointmentDateTime) {
            this.appointmentTimeError = '';
            return;
        }

        const selectedDate = new Date(this.appointmentDateTime);
        const hours = selectedDate.getUTCHours(); // Using UTC hours since Apex handles GMT

        if (hours < 9 || hours >= 17) {
            this.appointmentTimeError = 'Appointments can only be scheduled between 9 AM and 5 PM GMT.';
        } else {
            this.appointmentTimeError = '';
        }
    }
}
