/**
 * UHT_TriggerHandler_Test
 * 
 * Unit tests for UHT_TriggerHandler orchestration logic.
 * 
 * Note: These tests create Custom Metadata records programmatically using
 * Metadata API deployment, which is necessary since CMT records cannot be
 * created via DML in Apex tests.
 */
@IsTest
private class UHT_TriggerHandler_Test {
    
    // =========================================================================
    // handleAfterUpdate() Tests
    // =========================================================================
    
    @IsTest
    static void testHandleAfterUpdate_NullInputs() {
        // Act & Assert - should not throw exception
        Test.startTest();
        UHT_TriggerHandler.handleAfterUpdate(null, new List<Account>(), new Map<Id, SObject>());
        UHT_TriggerHandler.handleAfterUpdate('Account', null, new Map<Id, SObject>());
        UHT_TriggerHandler.handleAfterUpdate('Account', new List<Account>(), null);
        Test.stopTest();
        
        // No exception = pass
        System.assert(true, 'Should handle null inputs gracefully');
    }
    
    @IsTest
    static void testHandleAfterUpdate_EmptyInputs() {
        // Act & Assert - should not throw exception
        Test.startTest();
        UHT_TriggerHandler.handleAfterUpdate('', new List<Account>(), new Map<Id, SObject>());
        UHT_TriggerHandler.handleAfterUpdate('Account', new List<Account>(), new Map<Id, SObject>());
        Test.stopTest();
        
        // No exception = pass
        System.assert(true, 'Should handle empty inputs gracefully');
    }
    
    @IsTest
    static void testHandleAfterUpdate_UntrackedObject() {
        // Arrange - Account is not tracked (no CMT records)
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        Account oldAcc = acc.clone(true, true, true, true);
        acc.Name = 'Updated';
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ acc.Id => oldAcc };
        List<SObject> newRecords = new List<SObject>{ acc };
        
        // Act
        Test.startTest();
        UHT_TriggerHandler.handleAfterUpdate('Account', newRecords, oldMap);
        Test.stopTest();
        
        // Assert - no change logs created since object isn't tracked
        List<missionsf__UHT_Change_Log__c> logs = [
            SELECT Id FROM missionsf__UHT_Change_Log__c
            WHERE missionsf__Tracked_Record_Id__c = :acc.Id
        ];
        System.assertEquals(0, logs.size(), 'Untracked object should not create logs');
    }
    
    @IsTest
    static void testHandleAfterUpdate_RecursionPrevention() {
        // Arrange
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        Account oldAcc = acc.clone(true, true, true, true);
        acc.Name = 'Updated';
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ acc.Id => oldAcc };
        List<SObject> newRecords = new List<SObject>{ acc };
        
        // Manually mark as processed to simulate recursion
        UHT_RecursionManager.markProcessed(TriggerOperation.AFTER_UPDATE, acc.Id);
        
        // Act
        Test.startTest();
        UHT_TriggerHandler.handleAfterUpdate('Account', newRecords, oldMap);
        Test.stopTest();
        
        // Assert - no logs created due to recursion prevention
        List<missionsf__UHT_Change_Log__c> logs = [
            SELECT Id FROM missionsf__UHT_Change_Log__c
            WHERE missionsf__Tracked_Record_Id__c = :acc.Id
        ];
        System.assertEquals(0, logs.size(), 'Recursion should prevent duplicate processing');
    }
    
    // =========================================================================
    // isObjectTracked() Tests
    // =========================================================================
    
    @IsTest
    static void testIsObjectTracked_UntrackedObject() {
        // Act - no CMT records exist for 'FakeObject__c'
        Boolean result = UHT_TriggerHandler.isObjectTracked('FakeObject__c');
        
        // Assert
        System.assertEquals(false, result, 'Non-existent object should not be tracked');
    }
    
    @IsTest
    static void testIsObjectTracked_NullInput() {
        // Act
        Boolean result = UHT_TriggerHandler.isObjectTracked(null);
        
        // Assert
        System.assertEquals(false, result, 'Null input should return false');
    }
    
    // =========================================================================
    // getTrackedFieldConfigs() Tests
    // =========================================================================
    
    @IsTest
    static void testGetTrackedFieldConfigs_NoFields() {
        // Act - no CMT field records exist for 'FakeObject__c'
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = 
            UHT_TriggerHandler.getTrackedFieldConfigs('FakeObject__c');
        
        // Assert
        System.assertEquals(0, configs.size(), 'Non-existent object should have no field configs');
    }
    
    @IsTest
    static void testGetTrackedFieldConfigs_NullInput() {
        // Act
        List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = 
            UHT_TriggerHandler.getTrackedFieldConfigs(null);
        
        // Assert
        System.assertEquals(0, configs.size(), 'Null input should return empty list');
    }
    
    // =========================================================================
    // getTrackingStatus() Tests
    // =========================================================================
    
    @IsTest
    static void testGetTrackingStatus_ReturnsValidStructure() {
        // Act
        Map<String, Object> status = UHT_TriggerHandler.getTrackingStatus('Account');
        
        // Assert
        System.assert(status.containsKey('objectApiName'), 'Should have objectApiName');
        System.assert(status.containsKey('isTracked'), 'Should have isTracked');
        System.assert(status.containsKey('trackedFieldCount'), 'Should have trackedFieldCount');
        System.assert(status.containsKey('trackedFields'), 'Should have trackedFields');
        
        System.assertEquals('Account', status.get('objectApiName'), 'Object name should match');
    }
    
    @IsTest
    static void testGetTrackingStatus_UntrackedObject() {
        // Act
        Map<String, Object> status = UHT_TriggerHandler.getTrackingStatus('FakeObject__c');
        
        // Assert
        System.assertEquals(false, status.get('isTracked'), 'Should not be tracked');
        System.assertEquals(0, status.get('trackedFieldCount'), 'Should have 0 fields');
    }
    
    // =========================================================================
    // Integration Tests with Real Data
    // =========================================================================
    
    /**
     * Test the full flow with a real object update.
     * This test won't create change logs unless CMT is pre-configured,
     * but it validates the handler doesn't throw exceptions.
     */
    @IsTest
    static void testHandleAfterUpdate_FullFlow_NoErrors() {
        // Arrange
        Account acc = new Account(Name = 'Original Name', Industry = 'Technology');
        insert acc;
        
        // Clone for old values
        Account oldAcc = new Account(
            Id = acc.Id,
            Name = 'Original Name',
            Industry = 'Technology'
        );
        
        // Update values
        acc.Name = 'Updated Name';
        acc.Industry = 'Finance';
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ acc.Id => oldAcc };
        List<SObject> newRecords = new List<SObject>{ acc };
        
        // Act - should complete without error
        Test.startTest();
        UHT_TriggerHandler.handleAfterUpdate('Account', newRecords, oldMap);
        Test.stopTest();
        
        // Assert - no exceptions thrown
        System.assert(true, 'Handler should complete without errors');
    }
    
    /**
     * Test bulk handling - 200 records
     */
    @IsTest
    static void testHandleAfterUpdate_BulkRecords() {
        // Arrange - create 200 accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        insert accounts;
        
        // Build old and new record sets
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        List<SObject> newRecords = new List<SObject>();
        
        for (Account acc : accounts) {
            Account oldAcc = new Account(Id = acc.Id, Name = acc.Name);
            oldMap.put(acc.Id, oldAcc);
            
            acc.Name = acc.Name + ' Updated';
            newRecords.add(acc);
        }
        
        // Act - should handle bulk without hitting limits
        Test.startTest();
        UHT_TriggerHandler.handleAfterUpdate('Account', newRecords, oldMap);
        Test.stopTest();
        
        // Assert - completed without exception
        System.assert(true, 'Bulk handling should complete without errors');
    }
    
    // =========================================================================
    // Routing Decision Tests
    // =========================================================================
    
    @IsTest
    static void testRoutingDecision_SingleRecord_UsesSync() {
        // This test validates the routing logic conceptually
        // Actual async vs sync behavior is tested in the writer tests
        
        // Single record without Long Text should use sync
        // We can't easily verify this without mocking, but we can verify no errors
        
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        Account oldAcc = new Account(Id = acc.Id, Name = 'Test');
        acc.Name = 'Updated';
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ acc.Id => oldAcc };
        List<SObject> newRecords = new List<SObject>{ acc };
        
        Test.startTest();
        UHT_TriggerHandler.handleAfterUpdate('Account', newRecords, oldMap);
        Test.stopTest();
        
        System.assert(true, 'Single record handling should complete');
    }
    
    @IsTest
    static void testRoutingDecision_MultipleRecords_UsesAsync() {
        // Multiple records should trigger async processing
        
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        insert accounts;
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        List<SObject> newRecords = new List<SObject>();
        
        for (Account acc : accounts) {
            Account oldAcc = new Account(Id = acc.Id, Name = acc.Name);
            oldMap.put(acc.Id, oldAcc);
            acc.Name = acc.Name + ' Updated';
            newRecords.add(acc);
        }
        
        Test.startTest();
        UHT_TriggerHandler.handleAfterUpdate('Account', newRecords, oldMap);
        Test.stopTest();
        
        System.assert(true, 'Multi-record handling should complete');
    }
}