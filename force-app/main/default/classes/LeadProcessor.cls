public with sharing class LeadProcessor implements Database.Batchable<SObject> {
    
    // Define the query for the batch job
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id FROM Lead');
    }

    // Process each batch of records
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (SObject sObj : scope) {
            Lead leadRecord = (Lead) sObj;
            leadRecord.LeadSource = 'Dreamforce';
            leadsToUpdate.add(leadRecord);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }

    // Finish method
    public void finish(Database.BatchableContext BC) {
        // You can add any post-processing logic here if needed
    }
}
