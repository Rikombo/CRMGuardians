public with sharing class DoctorController {

    @AuraEnabled(cacheable=true)
    public static List<DoctorWrapper> getAvailableDoctors() {
        List<DoctorWrapper> doctorList = new List<DoctorWrapper>();

        List<Doctor__c> doctors = [SELECT Id, Name, Specialization__c 
                                   FROM Doctor__c 
                                   ORDER BY Name];

        for (Doctor__c doc : doctors) {
            doctorList.add(new DoctorWrapper(
                doc.Id, 
                doc.Name, 
                doc.Specialization__c
            ));
        }
        return doctorList;
    }

    public class DoctorWrapper {
        @AuraEnabled public String Id {get; set;}
        @AuraEnabled public String Name {get; set;}
        @AuraEnabled public String Specialization {get; set;}
        
        public DoctorWrapper(String id, String name, String specialization) {
            this.Id = id;
            this.Name = name;
            this.Specialization = specialization;
        }
    }
}
