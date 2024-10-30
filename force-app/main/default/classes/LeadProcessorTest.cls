@isTest
public class LeadProcessorTest {
    
    @isTest static void testLeadProcessorBatch() {
        // Insert 200 Lead records to test the batch job
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(new Lead(FirstName = 'Test', LastName = 'Lead' + i, Company = 'TestCompany', LeadSource = 'Web'));
        }
        insert leads;

        // Execute the LeadProcessor batch job
        Test.startTest();
        LeadProcessor batch = new LeadProcessor();
        Database.executeBatch(batch, 50); // Set batch size to 50 for testing
        Test.stopTest();

        // Query all Leads and verify the LeadSource is updated to 'Dreamforce'
        for (Lead lead : [SELECT LeadSource FROM Lead]) {
            System.assertEquals('Dreamforce', lead.LeadSource, 'LeadSource should be updated to Dreamforce');
        }
    }
}
