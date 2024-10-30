public with sharing class PatientDashboardController {
    @AuraEnabled(cacheable=true)
    public static List<Appointment__c> getAppointments() {
        if (!Schema.sObjectType.Appointment__c.isAccessible()) {
            return new List<Appointment__c>();
        }

        return [
            SELECT Id, Name, Appointment_Date__c, Status__c,
                   Service__c, Service__r.Name,
                   Reason_for_Visit__c,
                   Patient__c, Patient__r.Name,
                   Doctor__c, Doctor__r.Name
            FROM Appointment__c
            ORDER BY Appointment_Date__c
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static List<Appointment__c> searchAppointments(String doctorName, String appointmentDateStr) {
        if (!Schema.sObjectType.Appointment__c.isAccessible()) {
            return new List<Appointment__c>();
        }

        // Parse the appointmentDateStr into a Date object
        Date appointmentDate = null;
        if (!String.isBlank(appointmentDateStr)) {
            try {
                appointmentDate = Date.valueOf(appointmentDateStr);
            } catch (Exception e) {
                System.debug('Error parsing appointmentDateStr: ' + e.getMessage());
                // Optionally handle the error
            }
        }

        // Prepare search patterns
        String doctorNamePattern = null;
        if (!String.isBlank(doctorName)) {
            doctorNamePattern = '%' + String.escapeSingleQuotes(doctorName) + '%';
        }

        // Build the SOQL query with bind variables
        String query = 'SELECT Id, Name, Appointment_Date__c, Status__c, ' +
                       'Service__c, Service__r.Name, Reason_for_Visit__c, ' +
                       'Patient__c, Patient__r.Name, ' +
                       'Doctor__c, Doctor__r.Name ' +
                       'FROM Appointment__c';

        List<String> whereClauses = new List<String>();

        if (doctorNamePattern != null) {
            whereClauses.add('Doctor__r.Name LIKE :doctorNamePattern');
        }
        if (appointmentDate != null) {
            whereClauses.add('DAY_ONLY(Appointment_Date__c) = :appointmentDate');
        }

        if (!whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(whereClauses, ' AND ');
        }

        query += ' ORDER BY Appointment_Date__c LIMIT 100';

        System.debug('SOQL Query: ' + query);

        // Execute the query using Database.query with bind variables
        List<Appointment__c> appointments = Database.query(query);

        return appointments;
    }

    @AuraEnabled(cacheable=true)
    public static List<Appointment__c> getTodayAppointments() {
        if (!Schema.sObjectType.Appointment__c.isAccessible()) {
            return new List<Appointment__c>();
        }

        return [
            SELECT Id, Name, Appointment_Date__c, Status__c,
                   Service__c, Reason_for_Visit__c,
                   Patient__c, Patient__r.Name,
                   Doctor__c, Doctor__r.Name
            FROM Appointment__c
            WHERE DAY_ONLY(Appointment_Date__c) = :Date.today()
            ORDER BY Appointment_Date__c
            LIMIT 100
        ];
    }

    // ********** Doctor Methods **********

    @AuraEnabled(cacheable=true)
    public static List<Doctor__c> getDoctors() {
        if (!Schema.sObjectType.Doctor__c.isAccessible()) {
            return new List<Doctor__c>();
        }

        return [
            SELECT Id, Name, Availability__c, Specialization__c, Email__c
            FROM Doctor__c
            ORDER BY Name
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static List<Doctor__c> searchDoctors(String name, String specialization) {
        if (!Schema.sObjectType.Doctor__c.isAccessible()) {
            return new List<Doctor__c>();
        }

        // Prepare search patterns
        String namePattern = null;
        if (!String.isBlank(name)) {
            namePattern = '%' + String.escapeSingleQuotes(name) + '%';
        }
        String specializationPattern = null;
        if (!String.isBlank(specialization)) {
            specializationPattern = '%' + String.escapeSingleQuotes(specialization) + '%';
        }

        // Build the SOQL query with bind variables
        String query = 'SELECT Id, Name, Availability__c, Specialization__c, Email__c FROM Doctor__c';

        List<String> whereClauses = new List<String>();

        if (namePattern != null) {
            whereClauses.add('Name LIKE :namePattern');
        }
        if (specializationPattern != null) {
            whereClauses.add('Specialization__c LIKE :specializationPattern');
        }

        if (!whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(whereClauses, ' AND ');
        }

        query += ' ORDER BY Name LIMIT 100';

        System.debug('SOQL Query: ' + query);

        // Execute the query
        List<Doctor__c> doctors = Database.query(query);

        return doctors;
    }

}