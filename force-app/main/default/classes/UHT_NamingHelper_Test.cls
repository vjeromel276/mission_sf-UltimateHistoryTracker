/**
 * UHT_NamingHelper_Test
 * 
 * Unit tests for UHT_NamingHelper naming convention logic.
 */
@IsTest
private class UHT_NamingHelper_Test {

    // =========================================================================
    // getTriggerName() Tests
    // =========================================================================

    @IsTest
    static void testGetTriggerName_StandardObject() {
        System.assertEquals('UHTAccountTrigger', UHT_NamingHelper.getTriggerName('Account'));
        System.assertEquals('UHTContactTrigger', UHT_NamingHelper.getTriggerName('Contact'));
        System.assertEquals('UHTOpportunityTrigger', UHT_NamingHelper.getTriggerName('Opportunity'));
    }

    @IsTest
    static void testGetTriggerName_CustomObject() {
        // Custom objects get PascalCase trigger names (no underscores)
        // Each word split by underscore gets: first letter uppercase, rest lowercase
        System.assertEquals('UHTMyobjectTrigger', UHT_NamingHelper.getTriggerName('MyObject__c'));
        System.assertEquals('UHTInvoiceTrigger', UHT_NamingHelper.getTriggerName('Invoice__c'));
        System.assertEquals('UHTCustomObjectTrigger', UHT_NamingHelper.getTriggerName('Custom_Object__c'));
    }

    @IsTest
    static void testGetTriggerName_NamespacedObject() {
        // Namespaced objects also get PascalCase trigger names
        System.assertEquals('UHTMissionsfTestObjectTrigger', UHT_NamingHelper.getTriggerName('missionsf__Test_Object__c'));
        System.assertEquals('UHTNsMyCustomTrigger', UHT_NamingHelper.getTriggerName('ns__My_Custom__c'));
    }

    @IsTest
    static void testGetTriggerName_BlankInput() {
        System.assertEquals(null, UHT_NamingHelper.getTriggerName(null));
        System.assertEquals(null, UHT_NamingHelper.getTriggerName(''));
        System.assertEquals(null, UHT_NamingHelper.getTriggerName('   '));
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
    // getCleanBaseName() Tests
    // =========================================================================

    @IsTest
    static void testGetCleanBaseName_StandardObject() {
        // Standard objects return as-is (no __ in name)
        System.assertEquals('Account', UHT_NamingHelper.getCleanBaseName('Account'));
        System.assertEquals('Contact', UHT_NamingHelper.getCleanBaseName('Contact'));
        System.assertEquals('Opportunity', UHT_NamingHelper.getCleanBaseName('Opportunity'));
    }

    @IsTest
    static void testGetCleanBaseName_CustomObject() {
        // Custom objects: strip __c suffix
        System.assertEquals('MyObject', UHT_NamingHelper.getCleanBaseName('MyObject__c'));
        System.assertEquals('Invoice', UHT_NamingHelper.getCleanBaseName('Invoice__c'));
        System.assertEquals('My_Object', UHT_NamingHelper.getCleanBaseName('My_Object__c'));
    }

    @IsTest
    static void testGetCleanBaseName_NamespacedObject() {
        // Namespaced objects: strip namespace prefix and __c suffix
        System.assertEquals('Test_Object', UHT_NamingHelper.getCleanBaseName('missionsf__Test_Object__c'));
        System.assertEquals('Test', UHT_NamingHelper.getCleanBaseName('missionsf__Test__c'));
        System.assertEquals('My_Custom', UHT_NamingHelper.getCleanBaseName('ns__My_Custom__c'));
    }

    @IsTest
    static void testGetCleanBaseName_StandardField() {
        // Standard fields return as-is
        System.assertEquals('Industry', UHT_NamingHelper.getCleanBaseName('Industry'));
        System.assertEquals('Name', UHT_NamingHelper.getCleanBaseName('Name'));
    }

    @IsTest
    static void testGetCleanBaseName_CustomField() {
        // Custom fields: strip __c suffix
        System.assertEquals('My_Field', UHT_NamingHelper.getCleanBaseName('My_Field__c'));
        System.assertEquals('Status', UHT_NamingHelper.getCleanBaseName('Status__c'));
    }

    @IsTest
    static void testGetCleanBaseName_BlankInput() {
        System.assertEquals(null, UHT_NamingHelper.getCleanBaseName(null));
        System.assertEquals(null, UHT_NamingHelper.getCleanBaseName(''));
        System.assertEquals(null, UHT_NamingHelper.getCleanBaseName('   '));
    }

    // =========================================================================
    // getCleanLabel() Tests
    // =========================================================================

    @IsTest
    static void testGetCleanLabel_StandardObject() {
        // Standard objects return as-is
        System.assertEquals('Account', UHT_NamingHelper.getCleanLabel('Account'));
        System.assertEquals('Contact', UHT_NamingHelper.getCleanLabel('Contact'));
    }

    @IsTest
    static void testGetCleanLabel_CustomObject() {
        // Custom objects: strip __c and replace _ with space
        System.assertEquals('MyObject', UHT_NamingHelper.getCleanLabel('MyObject__c'));
        System.assertEquals('My Object', UHT_NamingHelper.getCleanLabel('My_Object__c'));
        System.assertEquals('Custom Object', UHT_NamingHelper.getCleanLabel('Custom_Object__c'));
    }

    @IsTest
    static void testGetCleanLabel_NamespacedObject() {
        // Namespaced objects: strip namespace and suffix, replace _ with space
        System.assertEquals('Test Object', UHT_NamingHelper.getCleanLabel('missionsf__Test_Object__c'));
        System.assertEquals('Test', UHT_NamingHelper.getCleanLabel('missionsf__Test__c'));
        System.assertEquals('My Custom', UHT_NamingHelper.getCleanLabel('ns__My_Custom__c'));
    }

    @IsTest
    static void testGetCleanLabel_BlankInput() {
        System.assertEquals(null, UHT_NamingHelper.getCleanLabel(null));
        System.assertEquals(null, UHT_NamingHelper.getCleanLabel(''));
        System.assertEquals(null, UHT_NamingHelper.getCleanLabel('   '));
    }
}