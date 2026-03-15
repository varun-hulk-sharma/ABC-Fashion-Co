@IsTest
private class GuestProfileAuthenticationControllerTest {
    private static final String TEST_TOKEN = 'TEST_PROFILE_TOKEN_123';
    
    @TestSetup
    static void setupTestData() {
        Id personRtId = getPersonAccountRecordTypeId();
        
        Account guestProfile = new Account(
            RecordTypeId = personRtId,
            FirstName = 'Varun',
            LastName = 'Sharma',
            PersonEmail = 'varun@test.com',
            Profile_Access_Token__c = TEST_TOKEN,
            Profile_Completed__c = false
        );
        insert guestProfile;
    }
    
    @IsTest
    static void testValidateToken_Success() {
        Test.startTest();
        Account result = GuestProfileAuthenticationController.validateToken(TEST_TOKEN);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected account to be returned for valid token.');
    }    
    
    @IsTest
    static void testUpdateCustomerProfile_MissingRequiredFields() {
        Boolean exceptionThrown = true;
        
        try {
            Test.startTest();
            GuestProfileAuthenticationController.updateCustomerProfile(TEST_TOKEN,'4165551234',null,'10','L');
            Test.stopTest();
        }
        catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        
        System.assertEquals(true, exceptionThrown, 'Expected AuraHandledException to be thrown.');
    }    
    
    @IsTest
    static void testUpdateCustomerProfile_Success() {
        Account guestProfile = getGuestProfile();
        
        Test.setMock(HttpCalloutMock.class, new LoyaltyProgramSuccessMock());
        
        Test.startTest();
        GuestProfileAuthenticationController.updateCustomerProfile(TEST_TOKEN,'4165551234',Date.newInstance(1990, 5, 10),'10','L');
        Test.stopTest();
        
        Account updated = [
            SELECT Id, Phone, PersonBirthdate, Shoe_Size__c, T_Shirt_Size__c,
                   Profile_Completed__c, Loyalty_Customer_ID__c
            FROM Account
            WHERE Id = :guestProfile.Id
        ];
        
        System.assertEquals('4165551234', updated.Phone, 'Phone should be updated.');
        System.assertEquals(Date.newInstance(1990, 5, 10), updated.PersonBirthdate, 'Birthdate should be updated.');
        System.assertEquals('10', updated.Shoe_Size__c, 'Shoe size should be updated.');
        System.assertEquals('L', updated.T_Shirt_Size__c, 'T-shirt size should be updated.');
        System.assertEquals(true, updated.Profile_Completed__c, 'Profile should be marked complete.');
        System.assertEquals(updated.Loyalty_Customer_ID__c, '12345678', 'Loyalty customer id should be updated from callout response.');
    }    
    
    @IsTest
    static void testProfileSync_400Response() {
        Account guestProfile = getGuestProfile();
        
        Test.setMock(HttpCalloutMock.class, new LoyaltyProgramBadRequestMock());
        
        try {
            Test.startTest();
            System.enqueueJob(new RetailCustomerProfileSync(guestProfile.Id,guestProfile.PersonEmail,'M','9'));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Profile sync failed. Status: 400') || e.getMessage().contains('tshirtSize is invalid'),
                'Unexpected exception message: ' + e.getMessage());
        }
    }    
    
    private class LoyaltyProgramSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            RetailCustomerProfileSync.RetailCustomerSyncRequest body =
                (RetailCustomerProfileSync.RetailCustomerSyncRequest)
                JSON.deserialize(req.getBody(), RetailCustomerProfileSync.RetailCustomerSyncRequest.class);
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success","customer_id":"12345678"}');
            return res;
        }
    }
    
    @IsTest
    static void testQueueable_UnexpectedResponse() {
        Account guestProfile = getGuestProfile();
        
        Test.setMock(HttpCalloutMock.class, new LoyaltyProgramUnexpectedResponseMock());
        
        try {
            Test.startTest();
            System.enqueueJob(new RetailCustomerProfileSync(guestProfile.Id,guestProfile.PersonEmail,'S','8'));
            Test.stopTest();
        }
        catch (Exception e) {
            System.assert(e.getMessage().contains('Unexpected response from Loyalty Program Service'),'Unexpected exception message: ' + e.getMessage());
        }
    }    
    
    private static Account getGuestProfile() {
        return [
            SELECT Id, PersonEmail, Phone, PersonBirthdate, Shoe_Size__c, T_Shirt_Size__c,
                   Profile_Completed__c, Profile_Access_Token__c, Loyalty_Customer_ID__c
            FROM Account
            WHERE Profile_Access_Token__c = :TEST_TOKEN
            LIMIT 1
        ];
    }    
    
    private static Id getPersonAccountRecordTypeId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsPersonType = true
            LIMIT 1
        ].Id;
    }
    
    private class LoyaltyProgramBadRequestMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"status":"error","message":"tshirtSize is invalid"}');
            return res;
        }
    }
    
    private class LoyaltyProgramUnexpectedResponseMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"status":"error","message":"Internal server error"}');
            return res;
        }
    }    
    
}