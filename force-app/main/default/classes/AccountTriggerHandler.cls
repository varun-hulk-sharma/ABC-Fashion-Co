public inherited sharing class AccountTriggerHandler {
    public static void beforeInsert(List<Account> newList) {
        RetailCustomerService.assignProfileAccessTokens(newList);
    }
    public static void afterInsert(List<Account> newList) {
        RetailCustomerService.sendLoyaltyProgramEmail(newList);
    }
}