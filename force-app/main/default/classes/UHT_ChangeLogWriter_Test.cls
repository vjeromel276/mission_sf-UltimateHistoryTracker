/**
 * UHT_ChangeLogWriter_Test
 * 
 * Unit tests for UHT_ChangeLogWriter sync and async writing.
 */
@IsTest
private class UHT_ChangeLogWriter_Test {
    
    // =========================================================================
    // writeSync() Tests
    // =========================================================================
    
    @IsTest
    static void testWriteSync_SingleChange() {
        // Arrange
        List<UHT_FieldChangeDetector.ChangeResult> changes = new List<UHT_FieldChangeDetector.ChangeResult>{
            new UHT_FieldChangeDetector.ChangeResult(
                'Account',
                createTestAccount().Id,
                'Name',
                'Old Name',
                'New Name',
                false
            )
        };
        
        // Act
        Test.startTest();
        List<Id> insertedIds = UHT_ChangeLogWriter.writeSync(changes);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, insertedIds.size(), 'Should insert 1 record');
        
        missionsf__UHT_Change_Log__c log = [
            SELECT missionsf__Tracked_Object__c, missionsf__Tracked_Field__c, 
                   missionsf__Old_Value__c, missionsf__New_Value__c,
                   missionsf__Change_Type__c, missionsf__Commit_User_Id__c
            FROM missionsf__UHT_Change_Log__c 
            WHERE Id = :insertedIds[0]
        ];
        
        System.assertEquals('Account', log.missionsf__Tracked_Object__c, 'Object should be Account');
        System.assertEquals('Name', log.missionsf__Tracked_Field__c, 'Field should be Name');
        System.assertEquals('Old Name', log.missionsf__Old_Value__c, 'Old value should match');
        System.assertEquals('New Name', log.missionsf__New_Value__c, 'New value should match');
        System.assertEquals('UPDATE', log.missionsf__Change_Type__c, 'Change type should be UPDATE');
        System.assertEquals(UserInfo.getUserId(), log.missionsf__Commit_User_Id__c, 'User should match');
    }
    
    @IsTest
    static void testWriteSync_MultipleChanges() {
        // Arrange
        Account testAccount = createTestAccount();
        List<UHT_FieldChangeDetector.ChangeResult> changes = new List<UHT_FieldChangeDetector.ChangeResult>{
            new UHT_FieldChangeDetector.ChangeResult('Account', testAccount.Id, 'Name', 'Old', 'New', false),
            new UHT_FieldChangeDetector.ChangeResult('Account', testAccount.Id, 'Industry', 'Tech', 'Finance', false),
            new UHT_FieldChangeDetector.ChangeResult('Account', testAccount.Id, 'Phone', '111', '222', false)
        };
        
        // Act
        Test.startTest();
        List<Id> insertedIds = UHT_ChangeLogWriter.writeSync(changes);
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, insertedIds.size(), 'Should insert 3 records');
        
        List<missionsf__UHT_Change_Log__c> logs = [
            SELECT missionsf__Tracked_Field__c
            FROM missionsf__UHT_Change_Log__c
            WHERE Id IN :insertedIds
            ORDER BY missionsf__Tracked_Field__c
        ];
        
        System.assertEquals(3, logs.size(), 'Should have 3 log records');
    }
    
    @IsTest
    static void testWriteSync_NullChanges() {
        // Act
        List<Id> result = UHT_ChangeLogWriter.writeSync(null);
        
        // Assert
        System.assertEquals(0, result.size(), 'Null should return empty list');
    }
    
    @IsTest
    static void testWriteSync_EmptyChanges() {
        // Act
        List<Id> result = UHT_ChangeLogWriter.writeSync(new List<UHT_FieldChangeDetector.ChangeResult>());
        
        // Assert
        System.assertEquals(0, result.size(), 'Empty list should return empty list');
    }
    
    @IsTest
    static void testWriteSync_NullValues() {
        // Arrange - test that null old/new values are handled
        Account testAccount = createTestAccount();
        List<UHT_FieldChangeDetector.ChangeResult> changes = new List<UHT_FieldChangeDetector.ChangeResult>{
            new UHT_FieldChangeDetector.ChangeResult('Account', testAccount.Id, 'Description', null, 'New Value', false),
            new UHT_FieldChangeDetector.ChangeResult('Account', testAccount.Id, 'Website', 'Old Value', null, false)
        };
        
        // Act
        Test.startTest();
        List<Id> insertedIds = UHT_ChangeLogWriter.writeSync(changes);
        Test.stopTest();
        
        // Assert
        System.assertEquals(2, insertedIds.size(), 'Should insert 2 records');
        
        List<missionsf__UHT_Change_Log__c> logs = [
            SELECT missionsf__Old_Value__c, missionsf__New_Value__c
            FROM missionsf__UHT_Change_Log__c
            WHERE Id IN :insertedIds
            ORDER BY missionsf__Tracked_Field__c
        ];
        
        // Description: null -> 'New Value'
        System.assertEquals(null, logs[0].missionsf__Old_Value__c, 'Old value should be null');
        System.assertEquals('New Value', logs[0].missionsf__New_Value__c, 'New value should match');
        
        // Website: 'Old Value' -> null
        System.assertEquals('Old Value', logs[1].missionsf__Old_Value__c, 'Old value should match');
        System.assertEquals(null, logs[1].missionsf__New_Value__c, 'New value should be null');
    }
    
    // =========================================================================
    // writeAsync() Tests
    // =========================================================================
    
    @IsTest
    static void testWriteAsync_EnqueuesJob() {
        // Arrange
        Account testAccount = createTestAccount();
        List<UHT_FieldChangeDetector.ChangeResult> changes = new List<UHT_FieldChangeDetector.ChangeResult>{
            new UHT_FieldChangeDetector.ChangeResult('Account', testAccount.Id, 'Name', 'Old', 'New', true)
        };
        
        // Act
        Test.startTest();
        Id jobId = UHT_ChangeLogWriter.writeAsync(changes);
        Test.stopTest(); // Forces Queueable execution
        
        // Assert
        System.assertNotEquals(null, jobId, 'Should return job ID');
        
        // Verify record was created by the Queueable
        List<missionsf__UHT_Change_Log__c> logs = [
            SELECT Id FROM missionsf__UHT_Change_Log__c
            WHERE missionsf__Tracked_Record_Id__c = :testAccount.Id
        ];
        System.assertEquals(1, logs.size(), 'Queueable should have created 1 record');
    }
    
    @IsTest
    static void testWriteAsync_MultipleChanges() {
        // Arrange
        Account testAccount = createTestAccount();
        List<UHT_FieldChangeDetector.ChangeResult> changes = new List<UHT_FieldChangeDetector.ChangeResult>();
        for (Integer i = 0; i < 10; i++) {
            changes.add(new UHT_FieldChangeDetector.ChangeResult(
                'Account', testAccount.Id, 'Field' + i, 'Old' + i, 'New' + i, false
            ));
        }
        
        // Act
        Test.startTest();
        Id jobId = UHT_ChangeLogWriter.writeAsync(changes);
        Test.stopTest();
        
        // Assert
        List<missionsf__UHT_Change_Log__c> logs = [
            SELECT Id FROM missionsf__UHT_Change_Log__c
            WHERE missionsf__Tracked_Record_Id__c = :testAccount.Id
        ];
        System.assertEquals(10, logs.size(), 'Queueable should have created 10 records');
    }
    
    @IsTest
    static void testWriteAsync_NullChanges() {
        // Act
        Id result = UHT_ChangeLogWriter.writeAsync(null);
        
        // Assert
        System.assertEquals(null, result, 'Null should return null job ID');
    }
    
    @IsTest
    static void testWriteAsync_EmptyChanges() {
        // Act
        Id result = UHT_ChangeLogWriter.writeAsync(new List<UHT_FieldChangeDetector.ChangeResult>());
        
        // Assert
        System.assertEquals(null, result, 'Empty list should return null job ID');
    }
    
    // =========================================================================
    // truncateValue() Tests
    // =========================================================================
    
    @IsTest
    static void testTruncateValue_ShortValue() {
        // Arrange
        String shortValue = 'This is a short value';
        
        // Act
        String result = UHT_ChangeLogWriter.truncateValue(shortValue);
        
        // Assert
        System.assertEquals(shortValue, result, 'Short values should not be truncated');
    }
    
    @IsTest
    static void testTruncateValue_NullValue() {
        // Act
        String result = UHT_ChangeLogWriter.truncateValue(null);
        
        // Assert
        System.assertEquals(null, result, 'Null should return null');
    }
    
    @IsTest
    static void testTruncateValue_NullString() {
        // Act - String.valueOf(null) returns 'null'
        String result = UHT_ChangeLogWriter.truncateValue('null');
        
        // Assert
        System.assertEquals(null, result, '"null" string should return null');
    }
    
    @IsTest
    static void testTruncateValue_LongValue() {
        // Arrange - create a value longer than MAX_VALUE_LENGTH
        String longValue = '';
        for (Integer i = 0; i < 14000; i++) {
            longValue += '0123456789'; // 10 chars per iteration = 140,000 chars
        }
        System.assert(longValue.length() > UHT_ChangeLogWriter.MAX_VALUE_LENGTH, 
            'Test value should exceed max length');
        
        // Act
        String result = UHT_ChangeLogWriter.truncateValue(longValue);
        
        // Assert
        System.assertEquals(UHT_ChangeLogWriter.MAX_VALUE_LENGTH, result.length(), 
            'Result should be exactly MAX_VALUE_LENGTH');
        System.assert(result.endsWith('... [TRUNCATED]'), 
            'Truncated value should end with truncation indicator');
    }
    
    // =========================================================================
    // shouldUseAsync() Tests
    // =========================================================================
    
    @IsTest
    static void testShouldUseAsync_SmallBatch() {
        // Act - with fresh transaction, should have plenty of DML capacity
        Boolean result = UHT_ChangeLogWriter.shouldUseAsync(10);
        
        // Assert
        System.assertEquals(false, result, 'Small batch should not require async');
    }
    
    @IsTest
    static void testShouldUseAsync_LargeBatch() {
        // Act - request more than 50% of limit
        Boolean result = UHT_ChangeLogWriter.shouldUseAsync(6000);
        
        // Assert
        System.assertEquals(true, result, 'Large batch should require async');
    }
    
    // =========================================================================
    // getDmlCapacity() Tests
    // =========================================================================
    
    @IsTest
    static void testGetDmlCapacity_ReturnsValidData() {
        // Act
        Map<String, Integer> capacity = UHT_ChangeLogWriter.getDmlCapacity();
        
        // Assert
        System.assert(capacity.containsKey('used'), 'Should have used key');
        System.assert(capacity.containsKey('limit'), 'Should have limit key');
        System.assert(capacity.containsKey('remaining'), 'Should have remaining key');
        System.assertEquals(10000, capacity.get('limit'), 'Limit should be 10000');
        System.assertEquals(capacity.get('limit') - capacity.get('used'), capacity.get('remaining'), 
            'Remaining should equal limit minus used');
    }
    
    // =========================================================================
    // createLogRecords() Tests
    // =========================================================================
    
    @IsTest
    static void testCreateLogRecords_SetsAllFields() {
        // Arrange
        Account testAccount = createTestAccount();
        Datetime testTimestamp = Datetime.now();
        
        UHT_FieldChangeDetector.ChangeResult change = new UHT_FieldChangeDetector.ChangeResult(
            'Account', testAccount.Id, 'Name', 'Old Name', 'New Name', false
        );
        change.changeTimestamp = testTimestamp;
        change.changedByUserId = UserInfo.getUserId();
        
        List<UHT_FieldChangeDetector.ChangeResult> changes = new List<UHT_FieldChangeDetector.ChangeResult>{ change };
        
        // Act
        List<missionsf__UHT_Change_Log__c> logs = UHT_ChangeLogWriter.createLogRecords(changes);
        
        // Assert
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        missionsf__UHT_Change_Log__c log = logs[0];
        
        System.assertEquals(testAccount.Id, log.missionsf__Tracked_Record_Id__c, 'Record ID should match');
        System.assertEquals('Account', log.missionsf__Tracked_Object__c, 'Object should match');
        System.assertEquals('Name', log.missionsf__Tracked_Field__c, 'Field should match');
        System.assertEquals('Old Name', log.missionsf__Old_Value__c, 'Old value should match');
        System.assertEquals('New Name', log.missionsf__New_Value__c, 'New value should match');
        System.assertEquals('UPDATE', log.missionsf__Change_Type__c, 'Change type should be UPDATE');
        System.assertEquals(testTimestamp, log.missionsf__Change_Timestamp__c, 'Timestamp should match');
        System.assertEquals(UserInfo.getUserId(), log.missionsf__Commit_User_Id__c, 'User should match');
    }
    
    // =========================================================================
    // Helper Methods
    // =========================================================================
    
    /**
     * Create a test Account record
     */
    private static Account createTestAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }
}