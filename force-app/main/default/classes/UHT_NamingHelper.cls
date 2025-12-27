/**
 * UHT_NamingHelper
 * 
 * Utility class for CDC-related naming conventions.
 * Handles the naming convention differences between standard and custom objects.
 * 
 * Naming Conventions:
 *   Standard objects: Account -> AccountChangeEvent -> AccountChangeEventTrigger
 *   Custom objects:   MyObject__c -> MyObject__ChangeEvent -> MyObjectChangeEventTrigger
 *   Namespaced:       ns__MyObject__c -> ns__MyObject__ChangeEvent -> NsMyObjectChangeEventTrigger
 */
public with sharing class UHT_NamingHelper {

    /**
     * Build the CDC ChangeEvent name for an object
     * This must match the actual Salesforce platform event name
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
     * Trigger names cannot contain underscores, so we convert to PascalCase
     * 
     * @param objectApiName The object API name (e.g., 'Account' or 'missionsf__Test_Object__c')
     * @return The trigger name (e.g., 'AccountChangeEventTrigger' or 'MissionsfTestObjectChangeEventTrigger')
     */
    public static String getTriggerName(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return null;
        }

        String baseName = objectApiName.trim();
        
        // Remove __c suffix if present
        if (baseName.endsWith('__c')) {
            baseName = baseName.removeEnd('__c');
        }
        
        // Split by underscores (handles both _ and __)
        List<String> parts = baseName.split('_+');
        
        // Convert each part to PascalCase and join
        String triggerName = '';
        for (String part : parts) {
            if (String.isNotBlank(part)) {
                triggerName += part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase();
            }
        }
        
        // Append ChangeEventTrigger
        return triggerName + 'ChangeEventTrigger';
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

    /**
     * Extract the clean base name from a Salesforce API name (object or field)
     * Strips namespace prefix and type suffix to get the user-defined name.
     * 
     * Uses the count of '__' occurrences to determine structure:
     *   0 = Standard (no namespace, no suffix)     : Account → Account
     *   1 = Simple custom (suffix only)            : Test__c → Test
     *   1 = Custom with underscore (suffix only)   : My_Object__c → My_Object
     *   2 = Namespaced (namespace + suffix)        : missionsf__Test__c → Test
     *   2 = Namespaced with underscore             : missionsf__My_Object__c → My_Object
     * 
     * @param apiName The full API name (e.g., 'missionsf__My_Object__c' or 'Account')
     * @return The clean base name (e.g., 'My_Object' or 'Account')
     */
    public static String getCleanBaseName(String apiName) {
        if (String.isBlank(apiName)) {
            return null;
        }
        
        String name = apiName.trim();
        
        // Count occurrences of '__'
        Integer doubleUnderscoreCount = 0;
        Integer searchIndex = 0;
        while ((searchIndex = name.indexOf('__', searchIndex)) != -1) {
            doubleUnderscoreCount++;
            searchIndex += 2; // Move past this '__'
        }
        
        // Process based on count
        if (doubleUnderscoreCount == 0) {
            // Standard object/field: Account, Industry
            return name;
        } 
        else if (doubleUnderscoreCount == 1) {
            // Simple custom: Test__c → Test, My_Object__c → My_Object
            // Just strip the suffix
            Integer suffixIndex = name.lastIndexOf('__');
            return name.substring(0, suffixIndex);
        } 
        else if (doubleUnderscoreCount == 2) {
            // Namespaced: missionsf__Test__c → Test, missionsf__My_Object__c → My_Object
            // Strip namespace prefix (first __) and suffix (last __)
            Integer firstDouble = name.indexOf('__');
            Integer lastDouble = name.lastIndexOf('__');
            return name.substring(firstDouble + 2, lastDouble);
        }
        else {
            // Unexpected pattern (3+ occurrences) - shouldn't happen with valid Salesforce names
            // Fall back to returning as-is
            return name;
        }
    }

    /**
     * Get a human-readable label from a Salesforce API name
     * Converts the clean base name to a label by replacing underscores with spaces.
     * 
     * Examples:
     *   missionsf__My_Object__c → My Object
     *   Test__c → Test
     *   Account → Account
     * 
     * @param apiName The full API name
     * @return Human-readable label
     */
    public static String getCleanLabel(String apiName) {
        String baseName = getCleanBaseName(apiName);
        if (String.isBlank(baseName)) {
            return null;
        }
        return baseName.replace('_', ' ');
    }
}