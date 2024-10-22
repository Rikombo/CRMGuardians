import { LightningElement, track } from 'lwc';
import getDoctors from '@salesforce/apex/ClinicDashboardController.getDoctors';
import searchDoctors from '@salesforce/apex/ClinicDashboardController.searchDoctors';

export default class DoctorList extends LightningElement {
    @track doctors = [];
    @track error;
    @track isLoading = false;

    doctorName = '';
    specialization = '';

    // Columns for the datatable
    columns = [
        {
            label: 'Doctor Name',
            fieldName: 'doctorLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        { label: 'Availability', fieldName: 'Availability__c' },
        { label: 'Specialization', fieldName: 'Specialization__c' },
        { label: 'Email', fieldName: 'Email__c', type: 'email' }
    ];

    connectedCallback() {
        this.loadDoctors();
    }

    loadDoctors() {
        this.isLoading = true;
        getDoctors()
            .then(result => {
                this.processDoctors(result);
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : 'Unknown error';
                console.error('Error loading doctors:', error);
                this.doctors = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleInputChange(event) {
        const field = event.target.name;
        if (field === 'doctorName') {
            this.doctorName = event.target.value;
        } else if (field === 'specialization') {
            this.specialization = event.target.value;
        }
    }

    handleSearch() {
        this.isLoading = true;
        searchDoctors({
            name: this.doctorName,
            specialization: this.specialization
        })
            .then(result => {
                this.processDoctors(result);
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : 'Unknown error';
                console.error('Error searching doctors:', error);
                this.doctors = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    processDoctors(data) {
        this.doctors = data.map(doctor => {
            return {
                ...doctor,
                doctorLink: `/lightning/r/Doctor__c/${doctor.Id}/view`,
                Name: doctor.Name || 'Unknown Doctor',
                Availability__c: doctor.Availability__c || 'N/A',
                Specialization__c: doctor.Specialization__c || 'N/A',
                Email__c: doctor.Email__c || 'N/A'
            };
        });
    }

    handleShowAll() {
        this.doctorName = '';
        this.specialization = '';
        this.loadDoctors();
    }
}
