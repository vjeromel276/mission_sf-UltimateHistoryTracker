/**
 * UHT_FieldChangeDetector
 * 
 * Pure comparison logic for detecting field changes between old and new record values.
 * This class has no knowledge of configuration - it receives a list of fields to check
 * and returns detected changes.
 * 
 * Responsibilities:
 *   - Compare old vs new values for specified fields
 *   - Return structured change results
 *   - Identify Long Text Area fields that require async processing
 * 
 * Usage:
 *   List<UHT_FieldChangeDetector.ChangeResult> changes = 
 *       UHT_FieldChangeDetector.detectChanges(
 *           'Account',
 *           trackedFieldConfigs,
 *           Trigger.new,
 *           Trigger.oldMap
 *       );
 */
global with sharing class UHT_FieldChangeDetector {
    
    // Field types that require asynchronous processing due to heap size concerns
    private static final Set<String> ASYNC_REQUIRED_TYPES = new Set<String>{
        'TEXTAREA',      // Long Text Area
        'LONGTEXTAREA',  // Alternative representation
        'RICHTEXTAREA',  // Rich Text
        'RICHTEXT'       // Alternative representation
    };
    
    /**
     * Wrapper class representing a tracked field configuration.
     * Passed in from the handler which owns the metadata lookup.
     */
    global class TrackedFieldConfig {
        global String fieldApiName;
        global String fieldType;
        
        global TrackedFieldConfig(String fieldApiName, String fieldType) {
            this.fieldApiName = fieldApiName;
            this.fieldType = fieldType;
        }
    }
    
    /**
     * Wrapper class representing a single field change detected.
     */
    global class ChangeResult {
        global String objectApiName;
        global Id recordId;
        global String fieldApiName;
        global Object oldValue;
        global Object newValue;
        global Boolean requiresAsync;
        global Id changedByUserId;
        global Datetime changeTimestamp;
        
        global ChangeResult(
            String objectApiName,
            Id recordId,
            String fieldApiName,
            Object oldValue,
            Object newValue,
            Boolean requiresAsync
        ) {
            this.objectApiName = objectApiName;
            this.recordId = recordId;
            this.fieldApiName = fieldApiName;
            this.oldValue = oldValue;
            this.newValue = newValue;
            this.requiresAsync = requiresAsync;
            this.changedByUserId = UserInfo.getUserId();
            this.changeTimestamp = Datetime.now();
        }
    }
    
    /**
     * Wrapper class for the complete detection result.
     * Includes the list of changes and a flag indicating if async processing is required.
     */
    global class DetectionResult {
        global List<ChangeResult> changes;
        global Boolean requiresAsync;
        
        global DetectionResult() {
            this.changes = new List<ChangeResult>();
            this.requiresAsync = false;
        }
        
        global void addChange(ChangeResult change) {
            this.changes.add(change);
            if (change.requiresAsync) {
                this.requiresAsync = true;
            }
        }
        
        global Boolean hasChanges() {
            return !this.changes.isEmpty();
        }
    }
    
    /**
     * Detect field changes for a list of records.
     * 
     * @param objectApiName The API name of the object being tracked
     * @param trackedFields List of field configurations to check
     * @param newRecords List of records from Trigger.new
     * @param oldMap Map of old records from Trigger.oldMap
     * @return DetectionResult containing all detected changes and async flag
     */
    global static DetectionResult detectChanges(
        String objectApiName,
        List<TrackedFieldConfig> trackedFields,
        List<SObject> newRecords,
        Map<Id, SObject> oldMap
    ) {
        DetectionResult result = new DetectionResult();
        
        // Validate inputs
        if (String.isBlank(objectApiName) || trackedFields == null || trackedFields.isEmpty() ||
            newRecords == null || newRecords.isEmpty() || oldMap == null || oldMap.isEmpty()) {
            return result;
        }
        
        // Build map of field API name to config for quick lookup
        Map<String, TrackedFieldConfig> fieldConfigMap = new Map<String, TrackedFieldConfig>();
        for (TrackedFieldConfig config : trackedFields) {
            if (config != null && String.isNotBlank(config.fieldApiName)) {
                fieldConfigMap.put(config.fieldApiName.toLowerCase(), config);
            }
        }
        
        // Iterate through records
        for (SObject newRecord : newRecords) {
            Id recordId = newRecord.Id;
            SObject oldRecord = oldMap.get(recordId);
            
            if (oldRecord == null) {
                continue; // Shouldn't happen in update context, but defensive
            }
            
            // Check each tracked field
            for (String fieldApiNameLower : fieldConfigMap.keySet()) {
                TrackedFieldConfig config = fieldConfigMap.get(fieldApiNameLower);
                String fieldApiName = config.fieldApiName;
                
                try {
                    Object oldValue = oldRecord.get(fieldApiName);
                    Object newValue = newRecord.get(fieldApiName);
                    
                    // Compare values
                    if (hasValueChanged(oldValue, newValue)) {
                        Boolean requiresAsync = isAsyncRequiredType(config.fieldType);
                        
                        ChangeResult change = new ChangeResult(
                            objectApiName,
                            recordId,
                            fieldApiName,
                            oldValue,
                            newValue,
                            requiresAsync
                        );
                        
                        result.addChange(change);
                    }
                } catch (SObjectException e) {
                    // Field doesn't exist or isn't accessible - skip silently
                    // This could happen if field was deleted after config was created
                    System.debug(LoggingLevel.WARN, 
                        'UHT: Unable to access field ' + fieldApiName + ' on ' + objectApiName + ': ' + e.getMessage());
                }
            }
        }
        
        return result;
    }
    
    /**
     * Compare two values to determine if they have changed.
     * Handles null comparisons and type-specific comparison logic.
     * 
     * @param oldValue The old field value
     * @param newValue The new field value
     * @return True if the values are different, false if same
     */
    global static Boolean hasValueChanged(Object oldValue, Object newValue) {
        // Both null - no change
        if (oldValue == null && newValue == null) {
            return false;
        }
        
        // One null, one not - changed
        if (oldValue == null || newValue == null) {
            return true;
        }
        
        // Both non-null - use standard comparison
        // Apex's != operator handles most types correctly including:
        // String, Integer, Decimal, Boolean, Date, DateTime, Id, etc.
        return oldValue != newValue;
    }
    
    /**
     * Determine if a field type requires asynchronous processing.
     * Long Text Area and Rich Text fields can consume significant heap space
     * and should be processed asynchronously.
     * 
     * @param fieldType The field type string (from Schema.DisplayType or FieldType__c)
     * @return True if async processing is required
     */
    global static Boolean isAsyncRequiredType(String fieldType) {
        if (String.isBlank(fieldType)) {
            return false;
        }
        
        return ASYNC_REQUIRED_TYPES.contains(fieldType.toUpperCase());
    }
    
    /**
     * Convert a list of ChangeResult objects to a serializable format.
     * Used when passing changes to a Queueable for async processing.
     * 
     * @param changes List of ChangeResult objects
     * @return JSON string representation
     */
    global static String serializeChanges(List<ChangeResult> changes) {
        if (changes == null || changes.isEmpty()) {
            return '[]';
        }
        
        List<Map<String, Object>> serializable = new List<Map<String, Object>>();
        for (ChangeResult change : changes) {
            Map<String, Object> changeMap = new Map<String, Object>{
                'objectApiName' => change.objectApiName,
                'recordId' => change.recordId,
                'fieldApiName' => change.fieldApiName,
                'oldValue' => String.valueOf(change.oldValue),
                'newValue' => String.valueOf(change.newValue),
                'requiresAsync' => change.requiresAsync,
                'changedByUserId' => change.changedByUserId,
                'changeTimestamp' => change.changeTimestamp
            };
            serializable.add(changeMap);
        }
        
        return JSON.serialize(serializable);
    }
    
    /**
     * Deserialize changes from JSON string back to ChangeResult objects.
     * Used in Queueable to reconstruct changes for processing.
     * 
     * @param jsonString JSON string from serializeChanges()
     * @return List of ChangeResult objects
     */
    global static List<ChangeResult> deserializeChanges(String jsonString) {
        List<ChangeResult> results = new List<ChangeResult>();
        
        if (String.isBlank(jsonString)) {
            return results;
        }
        
        try {
            List<Object> parsed = (List<Object>) JSON.deserializeUntyped(jsonString);
            
            for (Object item : parsed) {
                Map<String, Object> changeMap = (Map<String, Object>) item;
                
                ChangeResult change = new ChangeResult(
                    (String) changeMap.get('objectApiName'),
                    (Id) changeMap.get('recordId'),
                    (String) changeMap.get('fieldApiName'),
                    changeMap.get('oldValue'),
                    changeMap.get('newValue'),
                    (Boolean) changeMap.get('requiresAsync')
                );
                
                // Restore user and timestamp
                change.changedByUserId = (Id) changeMap.get('changedByUserId');
                String timestampStr = (String) changeMap.get('changeTimestamp');
                if (String.isNotBlank(timestampStr)) {
                    change.changeTimestamp = (Datetime) JSON.deserialize('"' + timestampStr + '"', Datetime.class);
                }
                
                results.add(change);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'UHT: Failed to deserialize changes: ' + e.getMessage());
        }
        
        return results;
    }
}