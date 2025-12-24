public with sharing class UHT_Account_CDC_Handler extends UHT_CDC_Handler {

    protected override void handleUpdate(CDCContext ctx) {

        // Safety checks
        if (ctx == null) return;
        if (ctx.entityName != 'Account') return;
        if (ctx.recordId == null) return;

        // CDC payload contains ONLY changed fields
        Object newValObj = ctx.rawPayload.get('Industry');
        if (newValObj == null) {
            // Industry was not changed in this update
            return;
        }

        String newValue = String.valueOf(newValObj);

        // Look up prior history row for this field
        missionsf__UHT_Change_Log__c priorLog;
        List<missionsf__UHT_Change_Log__c> priorLogs = [
            SELECT missionsf__New_Value__c
            FROM missionsf__UHT_Change_Log__c
            WHERE missionsf__Tracked_Object__c = 'Account'
              AND missionsf__Tracked_Record_Id__c = :ctx.recordId
              AND missionsf__Tracked_Field__c = 'Industry'
            ORDER BY missionsf__Change_Timestamp__c DESC
            LIMIT 1
        ];

        if (!priorLogs.isEmpty()) {
            priorLog = priorLogs[0];
        }

        String oldValue = priorLog != null
            ? priorLog.missionsf__New_Value__c
            : null;

        // Insert new history record
        missionsf__UHT_Change_Log__c logEntry = new missionsf__UHT_Change_Log__c(
            missionsf__Tracked_Object__c = 'Account',
            missionsf__Tracked_Record_Id__c = String.valueOf(ctx.recordId),
            missionsf__Tracked_Field__c = 'Industry',
            missionsf__Change_Type__c = ctx.changeType,
            missionsf__Old_Value__c = oldValue,
            missionsf__New_Value__c = newValue,
            missionsf__Change_Timestamp__c = ctx.commitTimestamp,
            missionsf__Commit_User_Id__c = ctx.commitUserId,
            missionsf__Commit_Number__c = ctx.commitNumber
        );

        insert logEntry;

        System.debug(LoggingLevel.INFO,
            'UHT Change Log written for Account Industry: ' +
            'Old=' + oldValue + ', New=' + newValue
        );
    }
}