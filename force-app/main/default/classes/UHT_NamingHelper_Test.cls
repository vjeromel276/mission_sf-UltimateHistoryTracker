/**
 * UHT_NamingHelper_Test
 * 
 * Unit tests for UHT_NamingHelper naming convention logic.
 */
@IsTest
private class UHT_NamingHelper_Test {

    // =========================================================================
    // getChangeEventName() Tests
    // =========================================================================

    @IsTest
    static void testGetChangeEventName_StandardObject() {
        System.assertEquals('AccountChangeEvent', UHT_NamingHelper.getChangeEventName('Account'));
        System.assertEquals('ContactChangeEvent', UHT_NamingHelper.getChangeEventName('Contact'));
        System.assertEquals('OpportunityChangeEvent', UHT_NamingHelper.getChangeEventName('Opportunity'));
    }

    @IsTest
    static void testGetChangeEventName_CustomObject() {
        System.assertEquals('MyObject__ChangeEvent', UHT_NamingHelper.getChangeEventName('MyObject__c'));
        System.assertEquals('Invoice__ChangeEvent', UHT_NamingHelper.getChangeEventName('Invoice__c'));
        System.assertEquals('Custom_Object__ChangeEvent', UHT_NamingHelper.getChangeEventName('Custom_Object__c'));
    }

    @IsTest
    static void testGetChangeEventName_NamespacedObject() {
        System.assertEquals('missionsf__Test_Object__ChangeEvent', UHT_NamingHelper.getChangeEventName('missionsf__Test_Object__c'));
        System.assertEquals('ns__My_Custom__ChangeEvent', UHT_NamingHelper.getChangeEventName('ns__My_Custom__c'));
    }

    @IsTest
    static void testGetChangeEventName_BlankInput() {
        System.assertEquals(null, UHT_NamingHelper.getChangeEventName(null));
        System.assertEquals(null, UHT_NamingHelper.getChangeEventName(''));
        System.assertEquals(null, UHT_NamingHelper.getChangeEventName('   '));
    }

    // =========================================================================
    // getTriggerName() Tests
    // =========================================================================

    @IsTest
    static void testGetTriggerName_StandardObject() {
        System.assertEquals('AccountChangeEventTrigger', UHT_NamingHelper.getTriggerName('Account'));
        System.assertEquals('ContactChangeEventTrigger', UHT_NamingHelper.getTriggerName('Contact'));
        System.assertEquals('OpportunityChangeEventTrigger', UHT_NamingHelper.getTriggerName('Opportunity'));
    }

    @IsTest
    static void testGetTriggerName_CustomObject() {
        // Custom objects get PascalCase trigger names (no underscores)
        // Each word split by underscore gets: first letter uppercase, rest lowercase
        System.assertEquals('MyobjectChangeEventTrigger', UHT_NamingHelper.getTriggerName('MyObject__c'));
        System.assertEquals('InvoiceChangeEventTrigger', UHT_NamingHelper.getTriggerName('Invoice__c'));
        System.assertEquals('CustomObjectChangeEventTrigger', UHT_NamingHelper.getTriggerName('Custom_Object__c'));
    }

    @IsTest
    static void testGetTriggerName_NamespacedObject() {
        // Namespaced objects also get PascalCase trigger names
        System.assertEquals('MissionsfTestObjectChangeEventTrigger', UHT_NamingHelper.getTriggerName('missionsf__Test_Object__c'));
        System.assertEquals('NsMyCustomChangeEventTrigger', UHT_NamingHelper.getTriggerName('ns__My_Custom__c'));
    }

    @IsTest
    static void testGetTriggerName_BlankInput() {
        System.assertEquals(null, UHT_NamingHelper.getTriggerName(null));
        System.assertEquals(null, UHT_NamingHelper.getTriggerName(''));
        System.assertEquals(null, UHT_NamingHelper.getTriggerName('   '));
    }

    // =========================================================================
    // getObjectApiName() Tests (Reverse Lookup)
    // =========================================================================

    @IsTest
    static void testGetObjectApiName_StandardObject() {
        System.assertEquals('Account', UHT_NamingHelper.getObjectApiName('AccountChangeEvent'));
        System.assertEquals('Contact', UHT_NamingHelper.getObjectApiName('ContactChangeEvent'));
        System.assertEquals('Opportunity', UHT_NamingHelper.getObjectApiName('OpportunityChangeEvent'));
    }

    @IsTest
    static void testGetObjectApiName_CustomObject() {
        System.assertEquals('MyObject__c', UHT_NamingHelper.getObjectApiName('MyObject__ChangeEvent'));
        System.assertEquals('Invoice__c', UHT_NamingHelper.getObjectApiName('Invoice__ChangeEvent'));
        System.assertEquals('Custom_Object__c', UHT_NamingHelper.getObjectApiName('Custom_Object__ChangeEvent'));
    }

    @IsTest
    static void testGetObjectApiName_NamespacedObject() {
        System.assertEquals('missionsf__Test_Object__c', UHT_NamingHelper.getObjectApiName('missionsf__Test_Object__ChangeEvent'));
        System.assertEquals('ns__My_Custom__c', UHT_NamingHelper.getObjectApiName('ns__My_Custom__ChangeEvent'));
    }

    @IsTest
    static void testGetObjectApiName_BlankInput() {
        System.assertEquals(null, UHT_NamingHelper.getObjectApiName(null));
        System.assertEquals(null, UHT_NamingHelper.getObjectApiName(''));
        System.assertEquals(null, UHT_NamingHelper.getObjectApiName('   '));
    }

    @IsTest
    static void testGetObjectApiName_NotChangeEvent() {
        // If it doesn't match the pattern, return as-is
        System.assertEquals('SomeRandomString', UHT_NamingHelper.getObjectApiName('SomeRandomString'));
        System.assertEquals('Account', UHT_NamingHelper.getObjectApiName('Account'));
    }

    // =========================================================================
    // isCustomObject() Tests
    // =========================================================================

    @IsTest
    static void testIsCustomObject_True() {
        System.assertEquals(true, UHT_NamingHelper.isCustomObject('MyObject__c'));
        System.assertEquals(true, UHT_NamingHelper.isCustomObject('Invoice__c'));
        System.assertEquals(true, UHT_NamingHelper.isCustomObject('Custom_Object__c'));
        System.assertEquals(true, UHT_NamingHelper.isCustomObject('missionsf__Test_Object__c'));
    }

    @IsTest
    static void testIsCustomObject_False() {
        System.assertEquals(false, UHT_NamingHelper.isCustomObject('Account'));
        System.assertEquals(false, UHT_NamingHelper.isCustomObject('Contact'));
        System.assertEquals(false, UHT_NamingHelper.isCustomObject('Opportunity'));
    }

    @IsTest
    static void testIsCustomObject_BlankInput() {
        System.assertEquals(false, UHT_NamingHelper.isCustomObject(null));
        System.assertEquals(false, UHT_NamingHelper.isCustomObject(''));
        System.assertEquals(false, UHT_NamingHelper.isCustomObject('   '));
    }

    // =========================================================================
    // Round-Trip Tests (Verify forward and reverse are consistent)
    // =========================================================================

    @IsTest
    static void testRoundTrip_StandardObject() {
        String original = 'Account';
        String changeEvent = UHT_NamingHelper.getChangeEventName(original);
        String reversed = UHT_NamingHelper.getObjectApiName(changeEvent);
        System.assertEquals(original, reversed, 'Round-trip failed for standard object');
    }

    @IsTest
    static void testRoundTrip_CustomObject() {
        String original = 'MyObject__c';
        String changeEvent = UHT_NamingHelper.getChangeEventName(original);
        String reversed = UHT_NamingHelper.getObjectApiName(changeEvent);
        System.assertEquals(original, reversed, 'Round-trip failed for custom object');
    }

    @IsTest
    static void testRoundTrip_NamespacedObject() {
        String original = 'missionsf__Test_Object__c';
        String changeEvent = UHT_NamingHelper.getChangeEventName(original);
        String reversed = UHT_NamingHelper.getObjectApiName(changeEvent);
        System.assertEquals(original, reversed, 'Round-trip failed for namespaced object');
    }
}