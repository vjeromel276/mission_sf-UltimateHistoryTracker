/**
 * UHT_CDC_Availability
 * 
 * Checks if an object is CDC-capable by checking if its ChangeEvent type exists.
 * Note: This checks capability, not whether CDC is actually enabled in Setup.
 * Actual CDC enablement is validated at trigger deployment time.
 */
public with sharing class UHT_CDC_Availability {

    /**
     * Returns true if the object supports CDC (ChangeEvent type exists)
     * Example input: 'Account' returns true if AccountChangeEvent schema exists
     * Example input: 'MyObject__c' returns true if MyObject__ChangeEvent schema exists
     */
    public static Boolean isEnabledForObject(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return false;
        }

        String changeEventName = UHT_NamingHelper.getChangeEventName(objectApiName);

        try {
            Schema.SObjectType t = Schema.getGlobalDescribe().get(changeEventName);
            return t != null;
        } catch (Exception e) {
            // Defensive: never let CDC checks break execution
            return false;
        }
    }
}