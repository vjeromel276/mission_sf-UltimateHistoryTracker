public with sharing class UHT_CDC_Availability {

    /**
     * Returns true if CDC is enabled for the given object
     * Example input: 'Account'
     */
    public static Boolean isEnabledForObject(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return false;
        }

        String changeEventName = objectApiName + 'ChangeEvent';

        try {
            Schema.SObjectType t = Schema.getGlobalDescribe().get(changeEventName);
            return t != null;
        } catch (Exception e) {
            // Defensive: never let CDC checks break execution
            return false;
        }
    }
}
