/**
 * UHT_FieldChangeDetector_Test
 * 
 * Unit tests for UHT_FieldChangeDetector field comparison logic.
 */
@IsTest
private class UHT_FieldChangeDetector_Test {
    
    // =========================================================================
    // detectChanges() Tests
    // =========================================================================
    
    @IsTest
    static void testDetectChanges_SingleFieldChanged() {
        // Arrange
        Account oldAccount = new Account(Id = '001000000000001AAA', Name = 'Old Name', Industry = 'Technology');
        Account newAccount = new Account(Id = '001000000000001AAA', Name = 'New Name', Industry = 'Technology');
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAccount.Id => oldAccount };
        List<SObject> newRecords = new List<SObject>{ newAccount };
        
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Name', 'Text'),
            new UHT_FieldChangeDetector.TrackedFieldConfig('Industry', 'Picklist')
        };
        
        // Act
        UHT_FieldChangeDetector.DetectionResult result = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, newRecords, oldMap);
        
        // Assert
        System.assertEquals(1, result.changes.size(), 'Should detect 1 change');
        System.assertEquals('Name', result.changes[0].fieldApiName, 'Should detect Name field change');
        System.assertEquals('Old Name', result.changes[0].oldValue, 'Old value should be Old Name');
        System.assertEquals('New Name', result.changes[0].newValue, 'New value should be New Name');
        System.assertEquals('001000000000001AAA', result.changes[0].recordId, 'Record ID should match');
        System.assertEquals('Account', result.changes[0].objectApiName, 'Object API name should be Account');
        System.assertEquals(false, result.requiresAsync, 'Text field should not require async');
    }
    
    @IsTest
    static void testDetectChanges_MultipleFieldsChanged() {
        // Arrange
        Account oldAccount = new Account(Id = '001000000000001AAA', Name = 'Old Name', Industry = 'Technology');
        Account newAccount = new Account(Id = '001000000000001AAA', Name = 'New Name', Industry = 'Finance');
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAccount.Id => oldAccount };
        List<SObject> newRecords = new List<SObject>{ newAccount };
        
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Name', 'Text'),
            new UHT_FieldChangeDetector.TrackedFieldConfig('Industry', 'Picklist')
        };
        
        // Act
        UHT_FieldChangeDetector.DetectionResult result = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, newRecords, oldMap);
        
        // Assert
        System.assertEquals(2, result.changes.size(), 'Should detect 2 changes');
    }
    
    @IsTest
    static void testDetectChanges_NoChanges() {
        // Arrange
        Account oldAccount = new Account(Id = '001000000000001AAA', Name = 'Same Name', Industry = 'Technology');
        Account newAccount = new Account(Id = '001000000000001AAA', Name = 'Same Name', Industry = 'Technology');
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAccount.Id => oldAccount };
        List<SObject> newRecords = new List<SObject>{ newAccount };
        
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Name', 'Text'),
            new UHT_FieldChangeDetector.TrackedFieldConfig('Industry', 'Picklist')
        };
        
        // Act
        UHT_FieldChangeDetector.DetectionResult result = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, newRecords, oldMap);
        
        // Assert
        System.assertEquals(0, result.changes.size(), 'Should detect no changes');
        System.assertEquals(false, result.hasChanges(), 'hasChanges should return false');
    }
    
    @IsTest
    static void testDetectChanges_MultipleRecords() {
        // Arrange
        Account oldAccount1 = new Account(Id = '001000000000001AAA', Name = 'Name 1');
        Account newAccount1 = new Account(Id = '001000000000001AAA', Name = 'Name 1 Updated');
        Account oldAccount2 = new Account(Id = '001000000000002AAA', Name = 'Name 2');
        Account newAccount2 = new Account(Id = '001000000000002AAA', Name = 'Name 2 Updated');
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ 
            oldAccount1.Id => oldAccount1,
            oldAccount2.Id => oldAccount2
        };
        List<SObject> newRecords = new List<SObject>{ newAccount1, newAccount2 };
        
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Name', 'Text')
        };
        
        // Act
        UHT_FieldChangeDetector.DetectionResult result = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, newRecords, oldMap);
        
        // Assert
        System.assertEquals(2, result.changes.size(), 'Should detect 2 changes (one per record)');
    }
    
    @IsTest
    static void testDetectChanges_LongTextAreaRequiresAsync() {
        // Arrange
        Account oldAccount = new Account(Id = '001000000000001AAA', Name = 'Old', Description = 'Old Description');
        Account newAccount = new Account(Id = '001000000000001AAA', Name = 'Old', Description = 'New Description');
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAccount.Id => oldAccount };
        List<SObject> newRecords = new List<SObject>{ newAccount };
        
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Description', 'LongTextArea')
        };
        
        // Act
        UHT_FieldChangeDetector.DetectionResult result = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, newRecords, oldMap);
        
        // Assert
        System.assertEquals(1, result.changes.size(), 'Should detect 1 change');
        System.assertEquals(true, result.changes[0].requiresAsync, 'LongTextArea should require async');
        System.assertEquals(true, result.requiresAsync, 'DetectionResult should flag async required');
    }
    
    @IsTest
    static void testDetectChanges_RichTextRequiresAsync() {
        // Arrange - using Description as proxy for rich text field
        Account oldAccount = new Account(Id = '001000000000001AAA', Description = '<p>Old</p>');
        Account newAccount = new Account(Id = '001000000000001AAA', Description = '<p>New</p>');
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAccount.Id => oldAccount };
        List<SObject> newRecords = new List<SObject>{ newAccount };
        
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Description', 'RichTextArea')
        };
        
        // Act
        UHT_FieldChangeDetector.DetectionResult result = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, newRecords, oldMap);
        
        // Assert
        System.assertEquals(true, result.requiresAsync, 'RichTextArea should require async');
    }
    
    @IsTest
    static void testDetectChanges_NullInputs() {
        // Arrange
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Name', 'Text')
        };
        
        // Act & Assert - should return empty result, not throw exception
        UHT_FieldChangeDetector.DetectionResult result1 = 
            UHT_FieldChangeDetector.detectChanges(null, configs, new List<SObject>(), new Map<Id, SObject>());
        System.assertEquals(0, result1.changes.size(), 'Null object name should return empty');
        
        UHT_FieldChangeDetector.DetectionResult result2 = 
            UHT_FieldChangeDetector.detectChanges('Account', null, new List<SObject>(), new Map<Id, SObject>());
        System.assertEquals(0, result2.changes.size(), 'Null configs should return empty');
        
        UHT_FieldChangeDetector.DetectionResult result3 = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, null, new Map<Id, SObject>());
        System.assertEquals(0, result3.changes.size(), 'Null new records should return empty');
        
        UHT_FieldChangeDetector.DetectionResult result4 = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, new List<SObject>(), null);
        System.assertEquals(0, result4.changes.size(), 'Null old map should return empty');
    }
    
    @IsTest
    static void testDetectChanges_EmptyInputs() {
        // Arrange
        List<UHT_FieldChangeDetector.TrackedFieldConfig> emptyConfigs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>();
        List<SObject> emptyRecords = new List<SObject>();
        Map<Id, SObject> emptyMap = new Map<Id, SObject>();
        
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Name', 'Text')
        };
        
        // Act & Assert
        UHT_FieldChangeDetector.DetectionResult result1 = 
            UHT_FieldChangeDetector.detectChanges('Account', emptyConfigs, emptyRecords, emptyMap);
        System.assertEquals(0, result1.changes.size(), 'Empty configs should return empty');
        
        UHT_FieldChangeDetector.DetectionResult result2 = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, emptyRecords, emptyMap);
        System.assertEquals(0, result2.changes.size(), 'Empty records should return empty');
    }
    
    @IsTest
    static void testDetectChanges_CapturesUserAndTimestamp() {
        // Arrange
        Account oldAccount = new Account(Id = '001000000000001AAA', Name = 'Old');
        Account newAccount = new Account(Id = '001000000000001AAA', Name = 'New');
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAccount.Id => oldAccount };
        List<SObject> newRecords = new List<SObject>{ newAccount };
        
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>{
            new UHT_FieldChangeDetector.TrackedFieldConfig('Name', 'Text')
        };
        
        // Act
        UHT_FieldChangeDetector.DetectionResult result = 
            UHT_FieldChangeDetector.detectChanges('Account', configs, newRecords, oldMap);
        
        // Assert
        System.assertEquals(UserInfo.getUserId(), result.changes[0].changedByUserId, 'Should capture current user');
        System.assertNotEquals(null, result.changes[0].changeTimestamp, 'Should capture timestamp');
    }
    
    // =========================================================================
    // hasValueChanged() Tests
    // =========================================================================
    
    @IsTest
    static void testHasValueChanged_BothNull() {
        System.assertEquals(false, UHT_FieldChangeDetector.hasValueChanged(null, null), 
            'Both null should return false');
    }
    
    @IsTest
    static void testHasValueChanged_OldNullNewNotNull() {
        System.assertEquals(true, UHT_FieldChangeDetector.hasValueChanged(null, 'value'), 
            'Null to value should return true');
    }
    
    @IsTest
    static void testHasValueChanged_OldNotNullNewNull() {
        System.assertEquals(true, UHT_FieldChangeDetector.hasValueChanged('value', null), 
            'Value to null should return true');
    }
    
    @IsTest
    static void testHasValueChanged_SameStrings() {
        System.assertEquals(false, UHT_FieldChangeDetector.hasValueChanged('same', 'same'), 
            'Same strings should return false');
    }
    
    @IsTest
    static void testHasValueChanged_DifferentStrings() {
        System.assertEquals(true, UHT_FieldChangeDetector.hasValueChanged('old', 'new'), 
            'Different strings should return true');
    }
    
    @IsTest
    static void testHasValueChanged_SameNumbers() {
        System.assertEquals(false, UHT_FieldChangeDetector.hasValueChanged(100, 100), 
            'Same integers should return false');
        System.assertEquals(false, UHT_FieldChangeDetector.hasValueChanged(100.50, 100.50), 
            'Same decimals should return false');
    }
    
    @IsTest
    static void testHasValueChanged_DifferentNumbers() {
        System.assertEquals(true, UHT_FieldChangeDetector.hasValueChanged(100, 200), 
            'Different integers should return true');
        System.assertEquals(true, UHT_FieldChangeDetector.hasValueChanged(100.50, 100.51), 
            'Different decimals should return true');
    }
    
    @IsTest
    static void testHasValueChanged_SameBooleans() {
        System.assertEquals(false, UHT_FieldChangeDetector.hasValueChanged(true, true), 
            'Same booleans should return false');
    }
    
    @IsTest
    static void testHasValueChanged_DifferentBooleans() {
        System.assertEquals(true, UHT_FieldChangeDetector.hasValueChanged(true, false), 
            'Different booleans should return true');
    }
    
    @IsTest
    static void testHasValueChanged_SameDates() {
        Date d = Date.today();
        System.assertEquals(false, UHT_FieldChangeDetector.hasValueChanged(d, d), 
            'Same dates should return false');
    }
    
    @IsTest
    static void testHasValueChanged_DifferentDates() {
        Date d1 = Date.today();
        Date d2 = Date.today().addDays(1);
        System.assertEquals(true, UHT_FieldChangeDetector.hasValueChanged(d1, d2), 
            'Different dates should return true');
    }
    
    // =========================================================================
    // isAsyncRequiredType() Tests
    // =========================================================================
    
    @IsTest
    static void testIsAsyncRequiredType_LongTextArea() {
        System.assertEquals(true, UHT_FieldChangeDetector.isAsyncRequiredType('LongTextArea'), 
            'LongTextArea should require async');
        System.assertEquals(true, UHT_FieldChangeDetector.isAsyncRequiredType('LONGTEXTAREA'), 
            'Case insensitive - LONGTEXTAREA should require async');
        System.assertEquals(true, UHT_FieldChangeDetector.isAsyncRequiredType('TextArea'), 
            'TextArea should require async');
    }
    
    @IsTest
    static void testIsAsyncRequiredType_RichText() {
        System.assertEquals(true, UHT_FieldChangeDetector.isAsyncRequiredType('RichTextArea'), 
            'RichTextArea should require async');
        System.assertEquals(true, UHT_FieldChangeDetector.isAsyncRequiredType('RichText'), 
            'RichText should require async');
    }
    
    @IsTest
    static void testIsAsyncRequiredType_StandardTypes() {
        System.assertEquals(false, UHT_FieldChangeDetector.isAsyncRequiredType('Text'), 
            'Text should not require async');
        System.assertEquals(false, UHT_FieldChangeDetector.isAsyncRequiredType('Number'), 
            'Number should not require async');
        System.assertEquals(false, UHT_FieldChangeDetector.isAsyncRequiredType('Picklist'), 
            'Picklist should not require async');
        System.assertEquals(false, UHT_FieldChangeDetector.isAsyncRequiredType('Currency'), 
            'Currency should not require async');
    }
    
    @IsTest
    static void testIsAsyncRequiredType_NullOrBlank() {
        System.assertEquals(false, UHT_FieldChangeDetector.isAsyncRequiredType(null), 
            'Null should return false');
        System.assertEquals(false, UHT_FieldChangeDetector.isAsyncRequiredType(''), 
            'Empty string should return false');
        System.assertEquals(false, UHT_FieldChangeDetector.isAsyncRequiredType('   '), 
            'Whitespace should return false');
    }
    
    // =========================================================================
    // Serialization Tests
    // =========================================================================
    
    @IsTest
    static void testSerializeAndDeserialize() {
        // Arrange
        List<UHT_FieldChangeDetector.ChangeResult> original = new List<UHT_FieldChangeDetector.ChangeResult>{
            new UHT_FieldChangeDetector.ChangeResult('Account', '001000000000001AAA', 'Name', 'Old', 'New', false),
            new UHT_FieldChangeDetector.ChangeResult('Account', '001000000000002AAA', 'Industry', 'Tech', 'Finance', false)
        };
        
        // Act
        String serialized = UHT_FieldChangeDetector.serializeChanges(original);
        List<UHT_FieldChangeDetector.ChangeResult> deserialized = 
            UHT_FieldChangeDetector.deserializeChanges(serialized);
        
        // Assert
        System.assertEquals(2, deserialized.size(), 'Should deserialize 2 changes');
        System.assertEquals('Account', deserialized[0].objectApiName, 'Object name should match');
        System.assertEquals('001000000000001AAA', deserialized[0].recordId, 'Record ID should match');
        System.assertEquals('Name', deserialized[0].fieldApiName, 'Field name should match');
        System.assertEquals('Old', deserialized[0].oldValue, 'Old value should match');
        System.assertEquals('New', deserialized[0].newValue, 'New value should match');
    }
    
    @IsTest
    static void testSerialize_EmptyList() {
        String result = UHT_FieldChangeDetector.serializeChanges(new List<UHT_FieldChangeDetector.ChangeResult>());
        System.assertEquals('[]', result, 'Empty list should serialize to []');
    }
    
    @IsTest
    static void testSerialize_NullList() {
        String result = UHT_FieldChangeDetector.serializeChanges(null);
        System.assertEquals('[]', result, 'Null should serialize to []');
    }
    
    @IsTest
    static void testDeserialize_EmptyString() {
        List<UHT_FieldChangeDetector.ChangeResult> result = 
            UHT_FieldChangeDetector.deserializeChanges('');
        System.assertEquals(0, result.size(), 'Empty string should deserialize to empty list');
    }
    
    @IsTest
    static void testDeserialize_NullString() {
        List<UHT_FieldChangeDetector.ChangeResult> result = 
            UHT_FieldChangeDetector.deserializeChanges(null);
        System.assertEquals(0, result.size(), 'Null should deserialize to empty list');
    }
    
    // =========================================================================
    // DetectionResult Wrapper Tests
    // =========================================================================
    
    @IsTest
    static void testDetectionResult_HasChanges() {
        // Arrange
        UHT_FieldChangeDetector.DetectionResult result = new UHT_FieldChangeDetector.DetectionResult();
        
        // Assert initial state
        System.assertEquals(false, result.hasChanges(), 'New result should have no changes');
        System.assertEquals(false, result.requiresAsync, 'New result should not require async');
        
        // Add a non-async change
        result.addChange(new UHT_FieldChangeDetector.ChangeResult('Account', '001000000000001AAA', 'Name', 'Old', 'New', false));
        System.assertEquals(true, result.hasChanges(), 'Should have changes after adding');
        System.assertEquals(false, result.requiresAsync, 'Should not require async for non-async field');
        
        // Add an async change
        result.addChange(new UHT_FieldChangeDetector.ChangeResult('Account', '001000000000001AAA', 'Description', 'Old', 'New', true));
        System.assertEquals(true, result.requiresAsync, 'Should require async after adding async field');
    }
}