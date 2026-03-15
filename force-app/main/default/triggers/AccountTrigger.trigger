trigger AccountTrigger on Account (before insert, after insert) {
    if (Trigger.isInsert) {
        if(Trigger.isBefore){
            AccountTriggerHandler.beforeInsert(Trigger.new);
        }
        if (Trigger.isAfter) {
            AccountTriggerHandler.afterInsert(Trigger.new);
        }
    }
}