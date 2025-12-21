public with sharing class UHT_Generic_CDC_Handler extends UHT_CDC_Handler {

    protected override void handleUpdate(CDCContext ctx) {

        if (ctx == null || ctx.entityName == null || ctx.recordId == null) {
            return;
        }

        // 1. Check if object is tracked (presence = enabled)
        if (!isObjectTracked(ctx.entityName)) {
            return;
        }

        // 2. Get tracked fields for this object
        Set<String> trackedFields = getTrackedFields(ctx.entityName);
        if (trackedFields.isEmpty()) {
            return;
        }

        // 3. Iterate over changed fields from CDC payload
        for (String fieldName : ctx.rawPayload.keySet()) {

            // Skip system / non-field keys
            if (isSystemField(fieldName)) continue;

            // Skip untracked fields
            if (!trackedFields.contains(fieldName)) continue;

            Object newValObj = ctx.rawPayload.get(fieldName);
            if (newValObj == null) continue;

            persistFieldChange(ctx, fieldName, String.valueOf(newValObj));
        }
    }

    // -----------------------
    // Helpers
    // -----------------------

    private static Boolean isObjectTracked(String objectApiName) {
        return [
            SELECT COUNT()
            FROM missionsf__UHT_Tracked_Object__mdt
            WHERE missionsf__ObjectApiName__c = :objectApiName
        ] > 0;
    }

    private static Set<String> getTrackedFields(String objectApiName) {
        Set<String> fields = new Set<String>();

        for (missionsf__UHT_Tracked_Field__mdt f :
            [SELECT missionsf__FieldApiName__c
             FROM missionsf__UHT_Tracked_Field__mdt
             WHERE missionsf__ObjectApiName__c = :objectApiName]
        ) {
            fields.add(f.missionsf__FieldApiName__c);
        }

        return fields;
    }

    private static Boolean isSystemField(String fieldName) {
        return fieldName == 'ChangeEventHeader'
            || fieldName == 'ReplayId'
            || fieldName == 'Id'
            || fieldName == 'LastModifiedDate';
    }

    private static void persistFieldChange(
        CDCContext ctx,
        String fieldName,
        String newValue
    ) {
        missionsf__UHT_Change_Log__c prior;

        List<missionsf__UHT_Change_Log__c> priorLogs = [
            SELECT missionsf__New_Value__c
            FROM missionsf__UHT_Change_Log__c
            WHERE missionsf__Tracked_Object__c = :ctx.entityName
              AND missionsf__Tracked_Record_Id__c = :String.valueOf(ctx.recordId)
              AND missionsf__Tracked_Field__c = :fieldName
            ORDER BY missionsf__Change_Timestamp__c DESC
            LIMIT 1
        ];

        if (!priorLogs.isEmpty()) {
            prior = priorLogs[0];
        }

        insert new missionsf__UHT_Change_Log__c(
            missionsf__Tracked_Object__c = ctx.entityName,
            missionsf__Tracked_Record_Id__c = String.valueOf(ctx.recordId),
            missionsf__Tracked_Field__c = fieldName,
            missionsf__Change_Type__c = ctx.changeType,
            missionsf__Old_Value__c = prior != null ? prior.missionsf__New_Value__c : null,
            missionsf__New_Value__c = newValue,
            missionsf__Change_Timestamp__c = ctx.commitTimestamp,
            missionsf__Commit_User_Id__c = ctx.commitUserId,
            missionsf__Commit_Number__c = ctx.commitNumber
        );
    }
}
