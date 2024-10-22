import { LightningElement, track } from 'lwc';
import getPatients from '@salesforce/apex/ClinicDashboardController.getPatients';
import searchPatients from '@salesforce/apex/ClinicDashboardController.searchPatients';

export default class PatientList extends LightningElement {
    @track patients = [];
    @track error;
    @track isLoading = false;

    patientName = '';
    createdDate = null;

    // Columns for the datatable
    columns = [
        {
            label: 'Patient Name',
            fieldName: 'patientLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        {
            label: 'DOB',
            fieldName: 'DOB__c',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'numeric',
                day: 'numeric'
            }
        },
        { label: 'Email', fieldName: 'Email__c', type: 'email' },
        { label: 'Phone', fieldName: 'Phone__c', type: 'phone' },
        { label: 'Gender', fieldName: 'Gender__c' },
        { label: 'Medical History', fieldName: 'Medical_History__c', type: 'text' }
    ];

    connectedCallback() {
        this.loadPatients();
    }

    loadPatients() {
        this.isLoading = true;
        getPatients()
            .then(result => {
                this.processPatients(result);
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : 'Unknown error';
                console.error('Error loading patients:', error);
                this.patients = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleInputChange(event) {
        const field = event.target.name;
        if (field === 'patientName') {
            this.patientName = event.target.value;
        } else if (field === 'createdDate') {
            this.createdDate = event.target.value; // 'YYYY-MM-DD'
        }
    }

    handleSearch() {
        this.isLoading = true;
        searchPatients({
            name: this.patientName,
            createdDateStr: this.createdDate || null
        })
            .then(result => {
                this.processPatients(result);
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : 'Unknown error';
                console.error('Error searching patients:', error);
                this.patients = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    processPatients(data) {
        this.patients = data.map(patient => {
            return {
                ...patient,
                patientLink: `/lightning/r/Patient__c/${patient.Id}/view`,
                Name: patient.Name || 'Unknown Patient',
                DOB__c: patient.DOB__c || null,
                Email__c: patient.Email__c || 'N/A',
                Phone__c: patient.Phone__c || 'N/A',
                Gender__c: patient.Gender__c || 'N/A',
                Medical_History__c: patient.Medical_History__c || 'N/A'
            };
        });
    }

    handleShowAll() {
        this.patientName = '';
        this.createdDate = null;
        this.loadPatients();
    }
}
