public class RetailCustomerProfileSync implements Queueable, Database.AllowsCallouts {
    private Id accountId;
    private String email;
    private String tShirtSize;
    private String shoeSize;
    
    public RetailCustomerProfileSync(Id accountId, String email, String tShirtSize, String shoeSize) {
        System.debug('RetailCustomerProfileSync Constructor Parameters:: ' + accountId + '|' + email + '|' + tShirtSize + '|' + shoeSize);
            
        this.accountId = accountId;
        this.email = email;
        this.tShirtSize = tShirtSize;
        this.shoeSize = shoeSize;
    }

    public void execute(QueueableContext context) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Loyalty_Program_Service/CreateProfile');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(20000);

        RetailCustomerSyncRequest payload = new RetailCustomerSyncRequest();
        payload.email = this.email;
        payload.shoeSize = this.shoeSize;
        payload.tShirtSize = this.tShirtSize;

        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {            
            RetailCustomerSyncResponse syncResponse = (RetailCustomerSyncResponse)JSON.deserialize(res.getBody(), RetailCustomerSyncResponse.class);
            System.debug(syncResponse);
            System.debug(syncResponse);
            
            Account accountUpdateRec = new Account(Id = this.accountId);
            accountUpdateRec.Loyalty_Customer_ID__c = !String.isBlank(syncResponse.customer_id) ? syncResponse.customer_id : '';
            
            try{
                update accountUpdateRec;
            }
            catch(DmlException e){
                system.debug('Error updating Customer Loyalty Id:: ' + e.getMessage());
                throw new DMLException('Profile sync succeeded but failed to update Loyalty Customer ID: ' + e.getMessage());            
            }              
            
            System.debug('Callout successful!');
        }	
        
        else if(res.getStatusCode() == 400){            
            RetailCustomerSyncResponse syncResponse = (RetailCustomerSyncResponse)JSON.deserialize(res.getBody(), RetailCustomerSyncResponse.class);
            System.debug(syncResponse);
            
            system.debug('Loyalty_Program_Service Error:: ' + syncResponse.message);
            throw new CalloutException('Profile sync failed. Status: ' + res.getStatusCode() + ': ' + syncResponse.message);
        }
        else {
            throw new CalloutException('Unexpected response from Loyalty Program Service. Status: ' +  res.getStatusCode() + '. Body: ' +  res.getBody());
        }
    }
    
    public class RetailCustomerSyncRequest {
        public String email;
        public String shoeSize;
        public String tShirtSize;
    }
    
    public class RetailCustomerSyncResponse {
        public String status;
        public String customer_id;
        public String message;
    }
}