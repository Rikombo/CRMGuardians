public with sharing class AddPrimaryContact implements Queueable {

    private Contact contactToClone;
    private String stateAbbreviation;

    // Constructor that accepts a Contact and a State abbreviation
    public AddPrimaryContact(Contact c, String stateAbbreviation) {
        this.contactToClone = c;
        this.stateAbbreviation = stateAbbreviation;
    }

    // Execute method that performs the main logic
    public void execute(QueueableContext context) {
        // Query up to 200 Accounts with the specified BillingState
        List<Account> accountsToProcess = [
            SELECT Id
            FROM Account
            WHERE BillingState = :stateAbbreviation
            LIMIT 200
        ];

        List<Contact> contactsToInsert = new List<Contact>();

        // For each Account, clone the Contact and associate it with the Account
        for (Account acc : accountsToProcess) {
            // Clone the contactToClone
            Contact clonedContact = contactToClone.clone(false, false, false, false);
            // Associate the cloned Contact with the current Account
            clonedContact.AccountId = acc.Id;
            contactsToInsert.add(clonedContact);
        }

        // Insert all cloned Contacts
        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }
}
