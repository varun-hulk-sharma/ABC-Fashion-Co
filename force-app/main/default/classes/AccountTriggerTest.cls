@IsTest()
public class AccountTriggerTest {        
    //Single test function to test both before and after insert
    @IsTest
    static void testInsert() {
        Id retailRtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = 'Retail_Customer'
            LIMIT 1
        ].Id;
        
        Account retailNoToken = new Account(
            RecordTypeId = retailRtId,
            FirstName = 'John',
            LastName = 'RetailOne',
            PersonEmail = 'john.retailone@example.com'
        );
        
        Account retailWithToken = new Account(
            RecordTypeId = retailRtId,
            FirstName = 'Jane',
            LastName = 'RetailTwo',
            PersonEmail = 'jane.retailtwo@example.com',
            Profile_Access_Token__c = 'EXISTING_TOKEN_123'
        );
        
        Account businessAcc = new Account(
            Name = 'New Business Account'
        );
        
        Test.startTest();
        insert new List<Account>{ retailNoToken, retailWithToken, businessAcc };            
        
        //**after insert coverage**
        
        //DO this assertion here because getEmailInvocations() returns the number of sendEmail calls made in the current transaction, so it needs to be before stopTest()    
        System.assertEquals(
            1,
            Limits.getEmailInvocations(),
            'The trigger should invoke email sending once.'
        );
        
        Test.stopTest();
        
        List<Account> insertedAccounts = [
            SELECT Id,
            IsPersonAccount,
            RecordTypeId,
            Profile_Access_Token__c,
            PersonContactId,
            FirstName,
            LastName,
            Name
            FROM Account
            WHERE Id IN :new List<Id>{ retailNoToken.Id, retailWithToken.Id, businessAcc.Id }
        ];
        
        Map<Id, Account> acctMap = new Map<Id, Account>(insertedAccounts);
        
        Account insertedRetailNoToken = acctMap.get(retailNoToken.Id);
        Account insertedRetailWithToken = acctMap.get(retailWithToken.Id);
        Account insertedBusiness = acctMap.get(businessAcc.Id);
        
        //**before insert coverage**
        // retail person account with blank token should get one
        System.assertNotEquals(
            null,
            insertedRetailNoToken.Profile_Access_Token__c,
            'Retail customer without a token should get a generated token.'
        );
        
        // retail person account with existing token should keep it
        System.assertEquals(
            'EXISTING_TOKEN_123',
            insertedRetailWithToken.Profile_Access_Token__c,
            'Existing token should not be overwritten.'
        );
        
        // business account should not get token
        System.assertEquals(
            null,
            insertedBusiness.Profile_Access_Token__c,
            'Business account should not receive a profile access token.'
        );
    }    
    
}