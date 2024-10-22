public with sharing class PatientController {

    @AuraEnabled(cacheable=true)
    public static List<PatientWrapper> getPatients() {
        List<PatientWrapper> patientList = new List<PatientWrapper>();

        List<Patient__c> patients = [SELECT Id, Name, CreatedDate 
                                     FROM Patient__c 
                                     ORDER BY CreatedDate DESC
                                     LIMIT 20];

        for (Patient__c pat : patients) {
            patientList.add(new PatientWrapper(
                pat.Id, 
                pat.Name, 
                String.valueOf(pat.CreatedDate)
            ));
        }
        return patientList;
    }

    public class PatientWrapper {
        @AuraEnabled public String Id {get; set;}
        @AuraEnabled public String Name {get; set;}
        @AuraEnabled public String CreatedDate {get; set;}
        
        public PatientWrapper(String id, String name, String createdDate) {
            this.Id = id;
            this.Name = name;
            this.CreatedDate = createdDate;
        }
    }
}
