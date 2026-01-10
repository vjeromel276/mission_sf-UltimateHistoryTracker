/**
 * UHT_NamingHelper
 * 
 * Utility class for UHT naming conventions.
 * Handles the naming convention differences between standard and custom objects.
 * 
 * Trigger Naming Conventions:
 *   Standard objects: Account -> UHTAccountTrigger
 *   Custom objects:   MyObject__c -> UHTMyObjectTrigger
 *   Custom with underscore: My_Object__c -> UHTMyObjectTrigger
 *   Namespaced:       ns__MyObject__c -> UHTNsMyObjectTrigger
 */
public with sharing class UHT_NamingHelper {

    /**
     * Build the UHT trigger name for an object.
     * Trigger names cannot contain underscores, so we convert to PascalCase
     * and prefix with 'UHT' to avoid naming collisions in customer orgs.
     * 
     * @param objectApiName The object API name (e.g., 'Account' or 'missionsf__Test_Object__c')
     * @return The trigger name (e.g., 'UHTAccountTrigger' or 'UHTMissionsfTestObjectTrigger')
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
        
        // Prefix with UHT and append Trigger
        return 'UHT' + triggerName + 'Trigger';
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