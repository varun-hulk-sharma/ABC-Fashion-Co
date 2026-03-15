public inherited sharing class RetailCustomerService {
    private static Id retailCustomerRecordTypeId;
    
    public static void assignProfileAccessTokens(List<Account> newAccounts) {
        for (Account acc : newAccounts) {
            if(isRetailCustomerPersonAccount(acc) && String.isBlank(acc.Profile_Access_Token__c)) {
                acc.Profile_Access_Token__c = generateToken();
            }
        }
    }
    
    public static void sendLoyaltyProgramEmail(List<Account> newAccounts) {
        OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'ABC Fashion Co' LIMIT 1];
        
        EmailTemplate rcTemplate = [ SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Retail_Customer_Welcome' LIMIT 1];        
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for(Account acc : newAccounts) {
            if(isRetailCustomerPersonAccount(acc)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(rcTemplate.Id);
                mail.setTargetObjectId(acc.PersonContactId);
                mail.setWhatId(acc.Id);
                mail.setSaveAsActivity(true);
                mail.setOrgWideEmailAddressId(owea.Id);
                
                emailList.add(mail);
            }
        }
        
        if(!emailList.isEmpty()) {
            Messaging.SendEmailResult[] emailSendResults = Messaging.sendEmail(emailList);
            
            if(emailSendResults.size() > 0){
                for(Messaging.SendEmailResult result : emailSendResults){
                    if(!result.isSuccess()){
                        for (Messaging.SendEmailError err : result.getErrors()) {
                            System.debug('Email error: ' + err.getTargetObjectId() + ' | '+ err.getMessage());
                        }
                    }
                }
            }
        }
    }
    
    private static Boolean isRetailCustomerPersonAccount(Account acc) {
        return acc.IsPersonAccount && acc.RecordTypeId == getRetailCustomerRecordTypeId();
    }   
    
    private static String generateToken() {
        Blob randomBytes = Crypto.generateAesKey(256);
        return EncodingUtil.convertToHex(randomBytes);
    }    
    
    private static Id getRetailCustomerRecordTypeId() {
        if(retailCustomerRecordTypeId == null) {
            retailCustomerRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Retail_Customer' LIMIT 1].Id;
        }
        return retailCustomerRecordTypeId;
    }    
}