/**
 * UHT_ChangeLogWriter
 * 
 * Writes field change records to UHT_Change_Log__c.
 * Provides both synchronous and asynchronous (Queueable) methods.
 * 
 * Sync: Used for single record updates without Long Text fields
 * Async: Used for bulk updates or when Long Text fields are involved
 * 
 * Usage:
 *   // Synchronous
 *   UHT_ChangeLogWriter.writeSync(changes);
 *   
 *   // Asynchronous
 *   UHT_ChangeLogWriter.writeAsync(changes);
 */
global with sharing class UHT_ChangeLogWriter {
    
    // Maximum length for text values before truncation
    // Long Text Area fields support 131072 characters
    @TestVisible
    private static final Integer MAX_VALUE_LENGTH = 131072;
    
    /**
     * Write changes synchronously (immediate DML).
     * Use for single record updates without Long Text fields.
     * 
     * @param changes List of ChangeResult objects to write
     * @return List of inserted UHT_Change_Log__c record IDs
     */
    global static List<Id> writeSync(List<UHT_FieldChangeDetector.ChangeResult> changes) {
        List<Id> insertedIds = new List<Id>();
        
        if (changes == null || changes.isEmpty()) {
            return insertedIds;
        }
        
        List<missionsf__UHT_Change_Log__c> logs = createLogRecords(changes);
        
        if (!logs.isEmpty()) {
            // Use Database.insert for partial success handling
            Database.SaveResult[] results = Database.insert(logs, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    insertedIds.add(results[i].getId());
                } else {
                    // Log errors but don't throw - we don't want to fail the user's transaction
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR, 
                            'UHT: Failed to insert change log: ' + err.getMessage());
                    }
                }
            }
        }
        
        return insertedIds;
    }
    
    /**
     * Write changes asynchronously via Queueable.
     * Use for bulk updates or when Long Text fields are involved.
     * 
     * @param changes List of ChangeResult objects to write
     * @return The Queueable job ID
     */
    global static Id writeAsync(List<UHT_FieldChangeDetector.ChangeResult> changes) {
        if (changes == null || changes.isEmpty()) {
            return null;
        }
        
        // Serialize changes for handoff to Queueable
        String serializedChanges = UHT_FieldChangeDetector.serializeChanges(changes);
        
        // Enqueue the job
        Id jobId = System.enqueueJob(new ChangeLogWriterQueueable(serializedChanges));
        
        return jobId;
    }
    
    /**
     * Create UHT_Change_Log__c records from ChangeResult objects.
     * Shared by both sync and async methods.
     * 
     * @param changes List of ChangeResult objects
     * @return List of UHT_Change_Log__c records ready for insert
     */
    @TestVisible
    private static List<missionsf__UHT_Change_Log__c> createLogRecords(
        List<UHT_FieldChangeDetector.ChangeResult> changes
    ) {
        List<missionsf__UHT_Change_Log__c> logs = new List<missionsf__UHT_Change_Log__c>();
        
        for (UHT_FieldChangeDetector.ChangeResult change : changes) {
            missionsf__UHT_Change_Log__c log = new missionsf__UHT_Change_Log__c();
            
            // Core fields
            log.missionsf__Tracked_Record_Id__c = change.recordId;
            log.missionsf__Tracked_Object__c = change.objectApiName;
            log.missionsf__Tracked_Field__c = change.fieldApiName;
            
            // Values - convert to string and truncate if needed
            log.missionsf__Old_Value__c = truncateValue(String.valueOf(change.oldValue));
            log.missionsf__New_Value__c = truncateValue(String.valueOf(change.newValue));
            
            // Change context
            log.missionsf__Change_Type__c = 'UPDATE';
            log.missionsf__Change_Timestamp__c = change.changeTimestamp;
            log.missionsf__Commit_User_Id__c = change.changedByUserId;
            
            logs.add(log);
        }
        
        return logs;
    }
    
    /**
     * Truncate a value string if it exceeds the maximum length.
     * Adds truncation indicator if truncated.
     * 
     * @param value The value to potentially truncate
     * @return The truncated (or original) value
     */
    @TestVisible
    private static String truncateValue(String value) {
        if (value == null) {
            return null;
        }
        
        // Handle 'null' string from String.valueOf(null)
        if (value == 'null') {
            return null;
        }
        
        if (value.length() <= MAX_VALUE_LENGTH) {
            return value;
        }
        
        // Truncate with indicator
        String truncationIndicator = '... [TRUNCATED]';
        Integer maxContentLength = MAX_VALUE_LENGTH - truncationIndicator.length();
        return value.substring(0, maxContentLength) + truncationIndicator;
    }
    
    /**
     * Queueable implementation for async writing.
     * Runs in a separate transaction with higher governor limits.
     */
    global class ChangeLogWriterQueueable implements Queueable {
        
        private String serializedChanges;
        
        global ChangeLogWriterQueueable(String serializedChanges) {
            this.serializedChanges = serializedChanges;
        }
        
        global void execute(QueueableContext context) {
            try {
                // Deserialize changes
                List<UHT_FieldChangeDetector.ChangeResult> changes = 
                    UHT_FieldChangeDetector.deserializeChanges(serializedChanges);
                
                if (changes.isEmpty()) {
                    System.debug(LoggingLevel.WARN, 'UHT: No changes to process in Queueable');
                    return;
                }
                
                // Create and insert log records
                List<missionsf__UHT_Change_Log__c> logs = createLogRecords(changes);
                
                if (!logs.isEmpty()) {
                    Database.SaveResult[] results = Database.insert(logs, false);
                    
                    Integer successCount = 0;
                    Integer failCount = 0;
                    
                    for (Database.SaveResult result : results) {
                        if (result.isSuccess()) {
                            successCount++;
                        } else {
                            failCount++;
                            for (Database.Error err : result.getErrors()) {
                                System.debug(LoggingLevel.ERROR, 
                                    'UHT Async: Failed to insert change log: ' + err.getMessage());
                            }
                        }
                    }
                    
                    System.debug(LoggingLevel.INFO, 
                        'UHT Async: Inserted ' + successCount + ' change logs, ' + failCount + ' failures');
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 
                    'UHT Async: Exception in Queueable: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
        }
    }
    
    /**
     * Check if we're approaching governor limits and should switch to async.
     * Can be used by handler to make routing decisions.
     * 
     * @param pendingDmlRows Number of DML rows that will be inserted
     * @return True if async is recommended
     */
    global static Boolean shouldUseAsync(Integer pendingDmlRows) {
        // Leave buffer for other DML in the transaction
        Integer dmlRowsUsed = Limits.getDmlRows();
        Integer dmlRowsLimit = Limits.getLimitDmlRows();
        Integer dmlRowsRemaining = dmlRowsLimit - dmlRowsUsed;
        
        // Use async if we'd use more than 50% of remaining DML rows
        // This leaves room for other operations in the transaction
        return pendingDmlRows > (dmlRowsRemaining / 2);
    }
    
    /**
     * Get the current DML capacity info for debugging/monitoring.
     * 
     * @return Map with capacity information
     */
    global static Map<String, Integer> getDmlCapacity() {
        return new Map<String, Integer>{
            'used' => Limits.getDmlRows(),
            'limit' => Limits.getLimitDmlRows(),
            'remaining' => Limits.getLimitDmlRows() - Limits.getDmlRows()
        };
    }
}