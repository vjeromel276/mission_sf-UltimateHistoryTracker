/**
 * UHT_RecursionManager_Test
 * 
 * Unit tests for UHT_RecursionManager recursion control logic.
 */
@IsTest
private class UHT_RecursionManager_Test {
    
    // =========================================================================
    // shouldProcess() Tests
    // =========================================================================
    
    @IsTest
    static void testShouldProcess_FirstCallReturnsTrue() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA'; // Fake Account ID
        
        // Act
        Boolean result = UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId);
        
        // Assert
        System.assertEquals(true, result, 'First call should return true');
    }
    
    @IsTest
    static void testShouldProcess_SecondCallReturnsFalse() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        
        // Act
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId);
        Boolean secondResult = UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId);
        
        // Assert
        System.assertEquals(false, secondResult, 'Second call for same record should return false');
    }
    
    @IsTest
    static void testShouldProcess_DifferentRecordReturnsTrue() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId1 = '001000000000001AAA';
        Id testId2 = '001000000000002AAA';
        
        // Act
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId1);
        Boolean result = UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId2);
        
        // Assert
        System.assertEquals(true, result, 'Different record should return true');
    }
    
    @IsTest
    static void testShouldProcess_DifferentOperationReturnsTrue() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        
        // Act
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId);
        Boolean result = UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_INSERT, testId);
        
        // Assert
        System.assertEquals(true, result, 'Same record with different operation should return true');
    }
    
    @IsTest
    static void testShouldProcess_NullOperation() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        
        // Act
        Boolean result = UHT_RecursionManager.shouldProcess(null, testId);
        
        // Assert
        System.assertEquals(false, result, 'Null operation should return false');
    }
    
    @IsTest
    static void testShouldProcess_NullRecordId() {
        // Arrange
        UHT_RecursionManager.clearAll();
        
        // Act
        Boolean result = UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, null);
        
        // Assert
        System.assertEquals(false, result, 'Null record ID should return false');
    }
    
    // =========================================================================
    // isProcessed() Tests
    // =========================================================================
    
    @IsTest
    static void testIsProcessed_NotProcessedReturnsFalse() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        
        // Act
        Boolean result = UHT_RecursionManager.isProcessed(TriggerOperation.AFTER_UPDATE, testId);
        
        // Assert
        System.assertEquals(false, result, 'Unprocessed record should return false');
    }
    
    @IsTest
    static void testIsProcessed_ProcessedReturnsTrue() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId);
        
        // Act
        Boolean result = UHT_RecursionManager.isProcessed(TriggerOperation.AFTER_UPDATE, testId);
        
        // Assert
        System.assertEquals(true, result, 'Processed record should return true');
    }
    
    @IsTest
    static void testIsProcessed_DoesNotMarkAsProcessed() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        
        // Act - call isProcessed (read-only check)
        UHT_RecursionManager.isProcessed(TriggerOperation.AFTER_UPDATE, testId);
        
        // Assert - shouldProcess should still return true since isProcessed doesn't mark
        Boolean result = UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId);
        System.assertEquals(true, result, 'isProcessed should not mark record as processed');
    }
    
    @IsTest
    static void testIsProcessed_NullInputs() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        
        // Act & Assert
        System.assertEquals(false, UHT_RecursionManager.isProcessed(null, testId), 'Null operation should return false');
        System.assertEquals(false, UHT_RecursionManager.isProcessed(TriggerOperation.AFTER_UPDATE, null), 'Null ID should return false');
    }
    
    // =========================================================================
    // markProcessed() Tests
    // =========================================================================
    
    @IsTest
    static void testMarkProcessed_MarksRecord() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        
        // Act
        UHT_RecursionManager.markProcessed(TriggerOperation.AFTER_UPDATE, testId);
        
        // Assert
        System.assertEquals(true, UHT_RecursionManager.isProcessed(TriggerOperation.AFTER_UPDATE, testId), 
            'Record should be marked as processed');
        System.assertEquals(false, UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId),
            'shouldProcess should return false after markProcessed');
    }
    
    @IsTest
    static void testMarkProcessed_NullInputsNoError() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        
        // Act & Assert - should not throw exception
        UHT_RecursionManager.markProcessed(null, testId);
        UHT_RecursionManager.markProcessed(TriggerOperation.AFTER_UPDATE, null);
        
        // Verify no side effects
        System.assertEquals(0, UHT_RecursionManager.getProcessedCount(TriggerOperation.AFTER_UPDATE),
            'Null inputs should not add records');
    }
    
    // =========================================================================
    // clearProcessed() Tests
    // =========================================================================
    
    @IsTest
    static void testClearProcessed_ClearsSpecificOperation() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId);
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_INSERT, testId);
        
        // Act
        UHT_RecursionManager.clearProcessed(TriggerOperation.AFTER_UPDATE);
        
        // Assert
        System.assertEquals(true, UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId),
            'Cleared operation should allow reprocessing');
        System.assertEquals(false, UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_INSERT, testId),
            'Other operations should not be affected');
    }
    
    // =========================================================================
    // clearAll() Tests
    // =========================================================================
    
    @IsTest
    static void testClearAll_ClearsAllOperations() {
        // Arrange
        UHT_RecursionManager.clearAll();
        Id testId = '001000000000001AAA';
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId);
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_INSERT, testId);
        
        // Act
        UHT_RecursionManager.clearAll();
        
        // Assert
        System.assertEquals(true, UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId),
            'AFTER_UPDATE should allow reprocessing after clearAll');
        System.assertEquals(true, UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_INSERT, testId),
            'AFTER_INSERT should allow reprocessing after clearAll');
    }
    
    // =========================================================================
    // getProcessedCount() Tests
    // =========================================================================
    
    @IsTest
    static void testGetProcessedCount_ReturnsCorrectCount() {
        // Arrange
        UHT_RecursionManager.clearAll();
        
        // Act
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, '001000000000001AAA');
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, '001000000000002AAA');
        UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, '001000000000003AAA');
        
        // Assert
        System.assertEquals(3, UHT_RecursionManager.getProcessedCount(TriggerOperation.AFTER_UPDATE),
            'Should count 3 processed records');
        System.assertEquals(0, UHT_RecursionManager.getProcessedCount(TriggerOperation.AFTER_INSERT),
            'Unprocessed operation should return 0');
    }
    
    @IsTest
    static void testGetProcessedCount_NullOperation() {
        // Arrange
        UHT_RecursionManager.clearAll();
        
        // Act & Assert
        System.assertEquals(0, UHT_RecursionManager.getProcessedCount(null),
            'Null operation should return 0');
    }
    
    // =========================================================================
    // Bulk Processing Tests
    // =========================================================================
    
    @IsTest
    static void testBulkProcessing_HandlesMultipleRecords() {
        // Arrange
        UHT_RecursionManager.clearAll();
        List<Id> testIds = new List<Id>();
        for (Integer i = 1; i <= 200; i++) {
            testIds.add(Id.valueOf('001000000000' + String.valueOf(i).leftPad(3, '0') + 'AAA'));
        }
        
        // Act - simulate first trigger execution
        Integer firstPassCount = 0;
        for (Id testId : testIds) {
            if (UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId)) {
                firstPassCount++;
            }
        }
        
        // Act - simulate workflow re-fire
        Integer secondPassCount = 0;
        for (Id testId : testIds) {
            if (UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, testId)) {
                secondPassCount++;
            }
        }
        
        // Assert
        System.assertEquals(200, firstPassCount, 'First pass should process all 200 records');
        System.assertEquals(0, secondPassCount, 'Second pass should process 0 records');
        System.assertEquals(200, UHT_RecursionManager.getProcessedCount(TriggerOperation.AFTER_UPDATE),
            'Should have 200 processed records');
    }
}