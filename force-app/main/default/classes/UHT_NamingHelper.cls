/**
 * UHT_NamingHelper
 * 
 * Centralized naming logic for CDC objects, events, and triggers.
 * Handles the naming convention differences between standard and custom objects.
 * 
 * Naming Conventions:
 *   Standard objects: Account -> AccountChangeEvent -> AccountChangeEventTrigger
 *   Custom objects:   MyObject__c -> MyObject__ChangeEvent -> MyObject__ChangeEventTrigger
 */
public with sharing class UHT_NamingHelper {

    /**
     * Build the CDC ChangeEvent name for an object
     * 
     * @param objectApiName The object API name (e.g., 'Account' or 'MyObject__c')
     * @return The ChangeEvent name (e.g., 'AccountChangeEvent' or 'MyObject__ChangeEvent')
     */
    public static String getChangeEventName(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return null;
        }

        // Custom objects: replace __c with __ChangeEvent
        if (objectApiName.endsWith('__c')) {
            return objectApiName.removeEnd('__c') + '__ChangeEvent';
        }

        // Standard objects: append ChangeEvent
        return objectApiName + 'ChangeEvent';
    }

    /**
     * Build the trigger name for a CDC ChangeEvent
     * 
     * @param objectApiName The object API name (e.g., 'Account' or 'MyObject__c')
     * @return The trigger name (e.g., 'AccountChangeEventTrigger' or 'MyObject__ChangeEventTrigger')
     */
    public static String getTriggerName(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return null;
        }

        // Custom objects: replace __c with __ChangeEventTrigger
        if (objectApiName.endsWith('__c')) {
            return objectApiName.removeEnd('__c') + '__ChangeEventTrigger';
        }

        // Standard objects: append ChangeEventTrigger
        return objectApiName + 'ChangeEventTrigger';
    }

    /**
     * Extract the object API name from a ChangeEvent type name
     * This is the reverse of getChangeEventName()
     * 
     * @param changeEventName The ChangeEvent name (e.g., 'AccountChangeEvent' or 'MyObject__ChangeEvent')
     * @return The object API name (e.g., 'Account' or 'MyObject__c')
     */
    public static String getObjectApiName(String changeEventName) {
        if (String.isBlank(changeEventName)) {
            return null;
        }

        // Custom objects: __ChangeEvent -> __c
        if (changeEventName.endsWith('__ChangeEvent')) {
            return changeEventName.removeEnd('__ChangeEvent') + '__c';
        }

        // Standard objects: remove ChangeEvent suffix
        if (changeEventName.endsWith('ChangeEvent')) {
            return changeEventName.removeEnd('ChangeEvent');
        }

        // Not a recognized ChangeEvent name, return as-is
        return changeEventName;
    }

    /**
     * Check if an object API name represents a custom object
     * 
     * @param objectApiName The object API name
     * @return True if custom object (ends with __c)
     */
    public static Boolean isCustomObject(String objectApiName) {
        return String.isNotBlank(objectApiName) && objectApiName.endsWith('__c');
    }
}