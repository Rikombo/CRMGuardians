import { LightningElement, track } from 'lwc';
import searchPatients from '@salesforce/apex/NewAppointmentController.searchPatients';
import searchDoctors from '@salesforce/apex/NewAppointmentController.searchDoctors';
import getServices from '@salesforce/apex/NewAppointmentController.getServices';
import getReasonsForVisit from '@salesforce/apex/NewAppointmentController.getReasonsForVisit';
import createAppointment from '@salesforce/apex/NewAppointmentController.createAppointment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NewAppointmentForm extends LightningElement {
    // Form Fields
    @track patientInput = '';
    @track selectedPatientId = '';
    @track doctorInput = '';
    @track selectedDoctorId = '';
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
                    value: reason.label
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
        }
    }

    // Handle Patient Selection
    handlePatientSelect(event) {
        this.selectedPatientId = event.detail.value;
        // Set patientInput based on selection for display
        const selectedOption = this.patientOptions.find(option => option.value === this.selectedPatientId);
        if(selectedOption) {
            this.patientInput = selectedOption.label;
        }
    }

    // Handle Doctor Input Change
    handleDoctorInputChange(event) {
        this.doctorInput = event.target.value;
        this.selectedDoctorId = '';
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
        }
    }

    // Handle Doctor Selection
    handleDoctorSelect(event) {
        this.selectedDoctorId = event.detail.value;
        // Set doctorInput based on selection for display
        const selectedOption = this.doctorOptions.find(option => option.value === this.selectedDoctorId);
        if(selectedOption) {
            this.doctorInput = selectedOption.label;
        }
    }

    // Handle Appointment Date & Time Change
    handleAppointmentDateTimeChange(event) {
        this.appointmentDateTime = event.target.value;
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
        }
    }

    // Handle Reset Button Click
    handleReset() {
        this.resetForm();
    }

    // Convert Local DateTime to GMT+2 String in 'YYYY-MM-DD HH:MM:SS' format
    convertToGMT(localDateTimeStr) {
        const localDate = new Date(localDateTimeStr);
        // Add 2 hours to the local time to align with GMT+2
        localDate.setHours(localDate.getHours() + 2);
        // Convert to ISO string and format it
        return localDate.toISOString().slice(0, 19).replace('T', ' ');
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
        this.doctorInput = '';
        this.selectedDoctorId = '';
        this.appointmentDateTime = '';
        this.selectedServiceId = '';
        this.selectedReason = '';
        this.patientOptions = [];
        this.doctorOptions = [];
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
}
