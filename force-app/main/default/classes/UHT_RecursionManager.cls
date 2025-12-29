/**
 * UHT_RecursionManager
 * 
 * Prevents double-processing of records when triggers re-fire due to
 * workflow field updates, Process Builder, or after-save Flows.
 * 
 * Tracks processed record IDs per TriggerOperation type within a single
 * transaction. Static variables reset automatically between transactions.
 * 
 * Usage in trigger handler:
 *   if (UHT_RecursionManager.shouldProcess(TriggerOperation.AFTER_UPDATE, recordId)) {
 *       // Process the record
 *   }
 */
global with sharing class UHT_RecursionManager {
    
    // Static map persists for duration of transaction, resets between transactions
    private static Map<TriggerOperation, Set<Id>> processedRecords = 
        new Map<TriggerOperation, Set<Id>>();
    
    /**
     * Check if a record should be processed for the given operation.
     * Returns true on first call for a record/operation combo, false on subsequent calls.
     * Automatically marks the record as processed when returning true.
     * 
     * @param op The trigger operation (e.g., TriggerOperation.AFTER_UPDATE)
     * @param recordId The ID of the record to check
     * @return True if the record should be processed, false if already processed
     */
    global static Boolean shouldProcess(TriggerOperation op, Id recordId) {
        if (op == null || recordId == null) {
            return false;
        }
        
        // Initialize set for this operation if needed
        if (!processedRecords.containsKey(op)) {
            processedRecords.put(op, new Set<Id>());
        }
        
        // Check if already processed
        if (processedRecords.get(op).contains(recordId)) {
            return false;
        }
        
        // Mark as processed and return true
        processedRecords.get(op).add(recordId);
        return true;
    }
    
    /**
     * Check if a record has already been processed for the given operation.
     * Does NOT mark the record as processed (read-only check).
     * 
     * @param op The trigger operation
     * @param recordId The ID of the record to check
     * @return True if already processed, false otherwise
     */
    global static Boolean isProcessed(TriggerOperation op, Id recordId) {
        if (op == null || recordId == null) {
            return false;
        }
        
        if (!processedRecords.containsKey(op)) {
            return false;
        }
        
        return processedRecords.get(op).contains(recordId);
    }
    
    /**
     * Manually mark a record as processed for a given operation.
     * Useful when processing is handled externally but recursion control is still needed.
     * 
     * @param op The trigger operation
     * @param recordId The ID of the record to mark
     */
    global static void markProcessed(TriggerOperation op, Id recordId) {
        if (op == null || recordId == null) {
            return;
        }
        
        if (!processedRecords.containsKey(op)) {
            processedRecords.put(op, new Set<Id>());
        }
        
        processedRecords.get(op).add(recordId);
    }
    
    /**
     * Clear processed records for a specific operation.
     * Primarily used for testing.
     * 
     * @param op The trigger operation to clear
     */
    @TestVisible
    private static void clearProcessed(TriggerOperation op) {
        if (op != null && processedRecords.containsKey(op)) {
            processedRecords.get(op).clear();
        }
    }
    
    /**
     * Clear all processed records across all operations.
     * Primarily used for testing.
     */
    @TestVisible
    private static void clearAll() {
        processedRecords.clear();
    }
    
    /**
     * Get count of processed records for a specific operation.
     * Primarily used for testing and debugging.
     * 
     * @param op The trigger operation
     * @return Number of records processed for this operation
     */
    @TestVisible
    private static Integer getProcessedCount(TriggerOperation op) {
        if (op == null || !processedRecords.containsKey(op)) {
            return 0;
        }
        return processedRecords.get(op).size();
    }
}