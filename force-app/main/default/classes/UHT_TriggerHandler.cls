/**
 * UHT_TriggerHandler
 *
 * Entry point for trigger-based field history tracking.
 * Called by deployed triggers on subscriber objects.
 *
 * Responsibilities:
 *   - Look up object/field tracking configuration from Custom Metadata
 *   - Coordinate recursion control
 *   - Route changes to sync or async processing
 *
 * Usage in deployed trigger:
 *   trigger AccountTrigger on Account (after update) {
 *       missionsf.UHT_TriggerHandler.handleAfterUpdate('Account', Trigger.new, Trigger.oldMap);
 *   }
 */
global with sharing class UHT_TriggerHandler {
  /**
   * Handle after update trigger events.
   * Main entry point called by deployed triggers.
   *
   * @param objectApiName The API name of the object (passed from trigger)
   * @param newRecords List of records from Trigger.new
   * @param oldMap Map of old records from Trigger.oldMap
   */
  global static void handleAfterUpdate(
    String objectApiName,
    List<SObject> newRecords,
    Map<Id, SObject> oldMap
  ) {
    // Step 1: Validate inputs
    if (
      String.isBlank(objectApiName) ||
      newRecords == null ||
      newRecords.isEmpty() ||
      oldMap == null
    ) {
      return;
    }

    // Step 2: Check if object is tracked (exit early if not)
    if (!isObjectTracked(objectApiName)) {
      return;
    }

    // Step 3: Get tracked fields for this object
    List<UHT_FieldChangeDetector.TrackedFieldConfig> trackedFields = getTrackedFieldConfigs(
      objectApiName
    );
    if (trackedFields.isEmpty()) {
      return;
    }

    // Step 4: Recursion check - filter to only records not yet processed
    List<SObject> recordsToProcess = new List<SObject>();
    for (SObject rec : newRecords) {
      if (
        UHT_RecursionManager.shouldProcess(
          TriggerOperation.AFTER_UPDATE,
          rec.Id
        )
      ) {
        recordsToProcess.add(rec);
      }
    }

    if (recordsToProcess.isEmpty()) {
      return;
    }

    // Step 5: Detect changes
    UHT_FieldChangeDetector.DetectionResult detectionResult = UHT_FieldChangeDetector.detectChanges(
      objectApiName,
      trackedFields,
      recordsToProcess,
      oldMap
    );

    if (!detectionResult.hasChanges()) {
      return;
    }

    // Step 6: Determine sync vs async routing
    // Use async if:
    //   - Any Long Text Area fields changed (heap size concern)
    //   - Bulk operation (more than 1 record)
    //   - Approaching DML limits
    Boolean useAsync =
      detectionResult.requiresAsync ||
      recordsToProcess.size() > 1 ||
      UHT_ChangeLogWriter.shouldUseAsync(detectionResult.changes.size());

    // Step 7: Write changes
    if (useAsync) {
      UHT_ChangeLogWriter.writeAsync(detectionResult.changes);
    } else {
      UHT_ChangeLogWriter.writeSync(detectionResult.changes);
    }
  }

  /**
   * Check if an object is configured for tracking.
   * Uses Custom Metadata getAll() to avoid SOQL limits.
   *
   * @param objectApiName The API name to check
   * @return True if object is tracked and active
   */
  @TestVisible
  private static Boolean isObjectTracked(String objectApiName) {
    // Use getAll() which is cached and doesn't count against SOQL limits
    Map<String, missionsf__UHT_Tracked_Object__mdt> allConfigs = missionsf__UHT_Tracked_Object__mdt.getAll();

    for (missionsf__UHT_Tracked_Object__mdt config : allConfigs.values()) {
      if (
        config.missionsf__ObjectApiName__c == objectApiName &&
        config.missionsf__IsActive__c == true
      ) {
        return true;
      }
    }

    return false;
  }

  /**
   * Get tracked field configurations for an object.
   * Returns list of TrackedFieldConfig wrappers for the detector.
   *
   * @param objectApiName The object API name
   * @return List of field configurations
   */
  @TestVisible
  private static List<UHT_FieldChangeDetector.TrackedFieldConfig> getTrackedFieldConfigs(
    String objectApiName
  ) {
    List<UHT_FieldChangeDetector.TrackedFieldConfig> configs = new List<UHT_FieldChangeDetector.TrackedFieldConfig>();

    // Query tracked fields for this object
    // Note: This SOQL is necessary since UHT_Tracked_Field__mdt.getAll()
    // returns all fields across all objects
    List<missionsf__UHT_Tracked_Field__mdt> trackedFields = [
      SELECT missionsf__FieldApiName__c, missionsf__FieldType__c
      FROM missionsf__UHT_Tracked_Field__mdt
      WHERE
        missionsf__ObjectApiName__c = :objectApiName
        AND missionsf__IsActive__c = TRUE
      WITH USER_MODE
    ];

    for (missionsf__UHT_Tracked_Field__mdt field : trackedFields) {
      configs.add(
        new UHT_FieldChangeDetector.TrackedFieldConfig(
          field.missionsf__FieldApiName__c,
          field.missionsf__FieldType__c
        )
      );
    }

    return configs;
  }

  /**
   * Utility method to check tracking status for debugging.
   * Can be called from Developer Console or debugging context.
   *
   * @param objectApiName The object to check
   * @return Map with tracking status information
   */
  global static Map<String, Object> getTrackingStatus(String objectApiName) {
    Map<String, Object> status = new Map<String, Object>();

    status.put('objectApiName', objectApiName);
    status.put('isTracked', isObjectTracked(objectApiName));

    List<UHT_FieldChangeDetector.TrackedFieldConfig> fields = getTrackedFieldConfigs(
      objectApiName
    );
    status.put('trackedFieldCount', fields.size());

    List<String> fieldNames = new List<String>();
    for (UHT_FieldChangeDetector.TrackedFieldConfig config : fields) {
      fieldNames.add(config.fieldApiName);
    }
    status.put('trackedFields', fieldNames);

    return status;
  }
}
