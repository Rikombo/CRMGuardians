public with sharing class AppointmentController {
    
    @AuraEnabled(cacheable=true)
    public static List<AppointmentWrapper> getAppointments() {
        List<AppointmentWrapper> appointmentList = new List<AppointmentWrapper>();

        List<Appointment__c> appointments = [SELECT Id, Appointment_Date__c, Status__c, 
                                             Patient__r.Name, Doctor__r.Name
                                             FROM Appointment__c 
                                             WHERE Appointment_Date__c >= TODAY
                                             ORDER BY Appointment_Date__c];

        for (Appointment__c appt : appointments) {
            appointmentList.add(new AppointmentWrapper(
                appt.Id, 
                appt.Patient__r.Name, 
                appt.Doctor__r.Name, 
                String.valueOf(appt.Appointment_Date__c),
                appt.Status__c
            ));
        }
        return appointmentList;
    }

    public class AppointmentWrapper {
        @AuraEnabled public String Id {get; set;}
        @AuraEnabled public String PatientName {get; set;}
        @AuraEnabled public String DoctorName {get; set;}
        @AuraEnabled public String AppointmentDate {get; set;}
        @AuraEnabled public String Status {get; set;}
        
        public AppointmentWrapper(String id, String patientName, String doctorName, String appointmentDate, String status) {
            this.Id = id;
            this.PatientName = patientName;
            this.DoctorName = doctorName;
            this.AppointmentDate = appointmentDate;
            this.Status = status;
        }
    }
}
