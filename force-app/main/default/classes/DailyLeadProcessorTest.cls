@isTest
public class DailyLeadProcessorTest {

    @isTest static void testDailyLeadProcessor() {
        // Insert 200 Lead records with a blank LeadSource field
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead' + i,
                Company = 'Test Company'
                // LeadSource is left blank
            ));
        }
        insert testLeads;

        // Schedule the DailyLeadProcessor class to run
        Test.startTest();
            // Define a CRON expression for immediate execution
            String CRON_EXP = '0 0 0 * * ?';
            String jobId = System.schedule('Test DailyLeadProcessor Job', CRON_EXP, new DailyLeadProcessor());
        Test.stopTest();

        // Verify that all Lead records were updated correctly
        List<Lead> updatedLeads = [SELECT LeadSource FROM Lead WHERE LeadSource = 'Dreamforce'];
        System.assertEquals(200, updatedLeads.size(), 'All Leads should have LeadSource updated to Dreamforce');

        // Additional assertion to ensure no Leads were left unprocessed
        Integer unprocessedLeadsCount = [SELECT COUNT() FROM Lead WHERE LeadSource = NULL];
        System.assertEquals(0, unprocessedLeadsCount, 'No Leads should have a blank LeadSource');
    }
}
