import { LightningElement, track } from 'lwc';
import getAppointments from '@salesforce/apex/ClinicDashboardController.getAppointments';
import searchAppointments from '@salesforce/apex/ClinicDashboardController.searchAppointments';

export default class AppointmentList extends LightningElement {
    @track appointments = [];
    @track error;
    @track isLoading = false;

    patientName = '';
    doctorName = '';
    appointmentDate = null;

    // Columns for the datatable
    columns = [
      {
          label: 'Appointment Name',
          fieldName: 'appointmentLink',
          type: 'url',
          typeAttributes: {
              label: { fieldName: 'Name' }, // Uses the Name field from the record
              target: '_blank'
          }
      },
      {
          label: 'Date',
          fieldName: 'Appointment_Date__c',
          type: 'date',
          typeAttributes: {
              day: 'numeric',
              month: 'numeric',
              year: 'numeric',
              hour: '2-digit',
              minute: '2-digit'
          }
      },
      { label: 'Doctor Name', fieldName: 'doctorName' },
      { label: 'Patient Name', fieldName: 'patientName' },
      { label: 'Service', fieldName: 'serviceName' },
      { label: 'Reason for Visit', fieldName: 'Reason_for_Visit__c' }
  ];
  

    connectedCallback() {
        this.loadAppointments();
    }

    loadAppointments() {
        this.isLoading = true;
        getAppointments()
            .then(result => {
                this.processAppointments(result);
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : 'Unknown error';
                console.error('Error loading appointments:', error);
                this.appointments = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleInputChange(event) {
        const field = event.target.name;
        if (field === 'patientName') {
            this.patientName = event.target.value;
        } else if (field === 'doctorName') {
            this.doctorName = event.target.value;
        } else if (field === 'appointmentDate') {
            this.appointmentDate = event.target.value; // 'YYYY-MM-DD'
        }
    }

    handleSearch() {
        this.isLoading = true;
        searchAppointments({
            patientName: this.patientName,
            doctorName: this.doctorName,
            appointmentDateStr: this.appointmentDate || null
        })
            .then(result => {
                this.processAppointments(result);
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : 'Unknown error';
                console.error('Error searching appointments:', error);
                this.appointments = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    processAppointments(data) {
        this.appointments = data.map(appointment => {
            return {
                ...appointment,
                appointmentLink: `/lightning/r/Appointment__c/${appointment.Id}/view`,
                // Use the Name field from the record directly
                doctorName: appointment.Doctor__r ? appointment.Doctor__r.Name : 'Unknown Doctor',
                patientName: appointment.Patient__r ? appointment.Patient__r.Name : 'Unknown Patient',
                serviceName: appointment.Service__r ? appointment.Service__r.Name : 'N/A',
                Reason_for_Visit__c: appointment.Reason_for_Visit__c || 'N/A'
            };
        });
    }

    handleShowAll() {
        this.patientName = '';
        this.doctorName = '';
        this.appointmentDate = null;
        this.loadAppointments();
    }

    handleTodayClick() {
        this.isLoading = true;
        this.patientName = '';
        this.doctorName = '';
        this.appointmentDate = new Date().toISOString().slice(0, 10); // 'YYYY-MM-DD'
        this.handleSearch();
    }
}
