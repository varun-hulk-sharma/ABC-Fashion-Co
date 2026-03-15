public without sharing class GuestProfileAuthenticationController {
    
    @AuraEnabled(cacheable=true)
    public static Account validateToken(String profileToken) {
        Account guestProfile = getGuestProfileByToken(profileToken);
        return guestProfile;
    }
    
    @AuraEnabled
    public static void updateCustomerProfile(String profileToken, String phoneNumber, Date bday, String shoeSize, String tSize){        
        Account guestProfile = getGuestProfileByToken(profileToken);

        if (guestProfile == null) {
            throw new AuraHandledException('Unable to update profile. User cannot be authenticated.');
        }

        if (bday == null || String.isBlank(shoeSize) || String.isBlank(tSize)) {
            throw new AuraHandledException('Please complete all required fields before saving.');
        }  
        
        Account accountUpdateRec = new Account();
        accountUpdateRec.Id = guestProfile.Id;
        accountUpdateRec.Shoe_Size__c = shoeSize;        
        accountUpdateRec.T_Shirt_Size__c = tSize;
        if(!String.isBlank(phoneNumber)) accountUpdateRec.phone = phoneNumber;
        accountUpdateRec.PersonBirthdate = bday;
        accountUpdateRec.Profile_Completed__c = true;
        
        try{
            update accountUpdateRec;
        }
        catch(DmlException e){
            system.debug('Error:: ' + e.getMessage());
            throw new AuraHandledException('We were unable to save your profile updates at this time.');            
        } 
        
        System.enqueueJob(new RetailCustomerProfileSync(guestProfile.Id, guestProfile.PersonEmail, tSize, shoeSize));
    }
    
    private static Account getGuestProfileByToken(String profileToken) {
        if (String.isBlank(profileToken)) {
            return null;
        }
        
        List<Account> profiles = [
            SELECT Id, Name, Phone, PersonBirthdate, Shoe_Size__c, T_Shirt_Size__c, PersonEmail
            FROM Account WHERE Profile_Access_Token__c = :profileToken LIMIT 1
        ];
        
        return profiles.isEmpty() ? null : profiles[0];
    }    
}