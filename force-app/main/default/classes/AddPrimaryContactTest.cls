@isTest
public class AddPrimaryContactTest {

    @isTest static void testAddPrimaryContact() {
        // Insert 50 Accounts with BillingState 'NY'
        List<Account> accountsNY = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            accountsNY.add(new Account(
                Name = 'Test Account NY ' + i,
                BillingState = 'NY'
            ));
        }
        insert accountsNY;

        // Insert 50 Accounts with BillingState 'CA'
        List<Account> accountsCA = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            accountsCA.add(new Account(
                Name = 'Test Account CA ' + i,
                BillingState = 'CA'
            ));
        }
        insert accountsCA;

        // Create a Contact sObject to clone
        Contact contactToClone = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com'
        );

        // Enqueue the AddPrimaryContact job
        Test.startTest();
            AddPrimaryContact job = new AddPrimaryContact(contactToClone, 'CA');
            System.enqueueJob(job);
        Test.stopTest();

        // Verify that a Contact was inserted for each Account with BillingState 'CA'
        List<Contact> insertedContacts = [SELECT Id, AccountId FROM Contact];
        System.assertEquals(50, insertedContacts.size(), 'Should have inserted 50 Contacts for CA Accounts');

        // Verify that each Contact is associated with one of the CA Accounts
        Set<Id> accountIdsCA = new Set<Id>();
        for (Account acc : accountsCA) {
            accountIdsCA.add(acc.Id);
        }

        for (Contact con : insertedContacts) {
            System.assert(
                accountIdsCA.contains(con.AccountId),
                'Contact should be associated with a CA Account'
            );
        }
    }
}
