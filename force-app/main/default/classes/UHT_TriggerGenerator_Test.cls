/**
 * UHT_TriggerGenerator_Test
 * 
 * Unit tests for UHT_TriggerGenerator trigger code generation.
 */
@IsTest
private class UHT_TriggerGenerator_Test {

    // =========================================================================
    // generate() Tests - Standard Objects
    // =========================================================================

    @IsTest
    static void testGenerate_StandardObject() {
        // Act
        UHT_TriggerGenerator.TriggerFiles result = UHT_TriggerGenerator.generate('Account');
        
        // Assert - trigger name
        System.assertEquals('UHTAccountTrigger', result.triggerName, 'Trigger name should match');
        
        // Assert - trigger code contains expected elements
        System.assert(result.triggerCode.contains('trigger UHTAccountTrigger on Account'), 
            'Should have correct trigger declaration');
        System.assert(result.triggerCode.contains('(after update)'), 
            'Should be after update trigger');
        System.assert(result.triggerCode.contains('missionsf.UHT_TriggerHandler.handleAfterUpdate'), 
            'Should call namespaced handler');
        System.assert(result.triggerCode.contains('\'Account\''), 
            'Should pass object API name as string');
        System.assert(result.triggerCode.contains('Trigger.new'), 
            'Should pass Trigger.new');
        System.assert(result.triggerCode.contains('Trigger.oldMap'), 
            'Should pass Trigger.oldMap');
        
        // Assert - meta XML
        System.assert(result.metaXml.contains('<apiVersion>65.0</apiVersion>'), 
            'Should have correct API version');
        System.assert(result.metaXml.contains('<status>Active</status>'), 
            'Should be active status');
    }

    @IsTest
    static void testGenerate_StandardObject_Contact() {
        // Act
        UHT_TriggerGenerator.TriggerFiles result = UHT_TriggerGenerator.generate('Contact');
        
        // Assert
        System.assertEquals('UHTContactTrigger', result.triggerName, 'Trigger name should match');
        System.assert(result.triggerCode.contains('trigger UHTContactTrigger on Contact'), 
            'Should have correct trigger declaration');
    }

    // =========================================================================
    // generate() Tests - Custom Objects
    // =========================================================================

    @IsTest
    static void testGenerate_CustomObject() {
        // Act
        UHT_TriggerGenerator.TriggerFiles result = UHT_TriggerGenerator.generate('Custom_Object__c');
        
        // Assert - trigger name (PascalCase, no underscores)
        System.assertEquals('UHTCustomObjectTrigger', result.triggerName, 'Trigger name should be PascalCase');
        
        // Assert - trigger code references original object API name
        System.assert(result.triggerCode.contains('trigger UHTCustomObjectTrigger on Custom_Object__c'), 
            'Should have correct trigger declaration with original object name');
        System.assert(result.triggerCode.contains('\'Custom_Object__c\''), 
            'Should pass original object API name to handler');
    }

    @IsTest
    static void testGenerate_CustomObject_Simple() {
        // Act
        UHT_TriggerGenerator.TriggerFiles result = UHT_TriggerGenerator.generate('Invoice__c');
        
        // Assert
        System.assertEquals('UHTInvoiceTrigger', result.triggerName, 'Trigger name should match');
        System.assert(result.triggerCode.contains('on Invoice__c'), 
            'Should reference original object name');
    }

    // =========================================================================
    // generate() Tests - Namespaced Objects
    // =========================================================================

    @IsTest
    static void testGenerate_NamespacedObject() {
        // Act
        UHT_TriggerGenerator.TriggerFiles result = UHT_TriggerGenerator.generate('missionsf__Test_Object__c');
        
        // Assert - trigger name includes namespace in PascalCase
        System.assertEquals('UHTMissionsfTestObjectTrigger', result.triggerName, 
            'Trigger name should include namespace in PascalCase');
        
        // Assert - trigger code references full namespaced object
        System.assert(result.triggerCode.contains('on missionsf__Test_Object__c'), 
            'Should reference full namespaced object name');
        System.assert(result.triggerCode.contains('\'missionsf__Test_Object__c\''), 
            'Should pass full namespaced object name to handler');
    }

    // =========================================================================
    // generate() Tests - Invalid Input
    // =========================================================================

    @IsTest
    static void testGenerate_NullInput() {
        // Act & Assert
        try {
            UHT_TriggerGenerator.generate(null);
            System.assert(false, 'Should have thrown exception');
        } catch (UHT_TriggerGenerator.TriggerGeneratorException e) {
            System.assertEquals('Object API name is required', e.getMessage(), 
                'Should have correct error message');
        }
    }

    @IsTest
    static void testGenerate_BlankInput() {
        // Act & Assert
        try {
            UHT_TriggerGenerator.generate('');
            System.assert(false, 'Should have thrown exception');
        } catch (UHT_TriggerGenerator.TriggerGeneratorException e) {
            System.assertEquals('Object API name is required', e.getMessage(), 
                'Should have correct error message');
        }
    }

    @IsTest
    static void testGenerate_WhitespaceInput() {
        // Act & Assert
        try {
            UHT_TriggerGenerator.generate('   ');
            System.assert(false, 'Should have thrown exception');
        } catch (UHT_TriggerGenerator.TriggerGeneratorException e) {
            System.assertEquals('Object API name is required', e.getMessage(), 
                'Should have correct error message');
        }
    }

    // =========================================================================
    // generate() Tests - Input Sanitization
    // =========================================================================

    @IsTest
    static void testGenerate_InputWithWhitespace() {
        // Act - input has leading/trailing whitespace
        UHT_TriggerGenerator.TriggerFiles result = UHT_TriggerGenerator.generate('  Account  ');
        
        // Assert - should be trimmed
        System.assertEquals('UHTAccountTrigger', result.triggerName, 
            'Should handle whitespace in input');
        System.assert(result.triggerCode.contains('on Account (after update)'), 
            'Should trim object name in trigger code');
    }

    // =========================================================================
    // TriggerFiles Wrapper Tests
    // =========================================================================

    @IsTest
    static void testTriggerFiles_AllPropertiesPopulated() {
        // Act
        UHT_TriggerGenerator.TriggerFiles result = UHT_TriggerGenerator.generate('Account');
        
        // Assert - all properties are populated
        System.assertNotEquals(null, result.triggerName, 'triggerName should not be null');
        System.assertNotEquals(null, result.triggerCode, 'triggerCode should not be null');
        System.assertNotEquals(null, result.metaXml, 'metaXml should not be null');
        
        System.assert(result.triggerName.length() > 0, 'triggerName should not be empty');
        System.assert(result.triggerCode.length() > 0, 'triggerCode should not be empty');
        System.assert(result.metaXml.length() > 0, 'metaXml should not be empty');
    }

    // =========================================================================
    // Meta XML Tests
    // =========================================================================

    @IsTest
    static void testGenerateMetaXml_ValidStructure() {
        // Act
        UHT_TriggerGenerator.TriggerFiles result = UHT_TriggerGenerator.generate('Account');
        
        // Assert - XML structure
        System.assert(result.metaXml.contains('<?xml version="1.0" encoding="UTF-8"?>'), 
            'Should have XML declaration');
        System.assert(result.metaXml.contains('<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">'), 
            'Should have ApexTrigger root element with namespace');
        System.assert(result.metaXml.contains('</ApexTrigger>'), 
            'Should have closing ApexTrigger tag');
    }
}