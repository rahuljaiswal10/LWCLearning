public class PropertyUtility {
    public static void newListedProperties(){
        List<Property__c> newPropList = [SELECT Id, Name, Broker__r.Email__c, Days_On_Market__c FROM Property__c where Days_On_Market__c <= 30];
        for(Property__c prop : newPropList){
            System.debug(prop.Name+':'+prop.Broker__r.Email__c);
        }
    }
}