public with sharing class UHT_Account_CDC_Handler extends UHT_CDC_Handler {

    protected override void handleCreate(CDCContext ctx) {
        System.debug(LoggingLevel.INFO, 'UHT Account CREATE: ' + ctx.recordId);
    }

    protected override void handleUpdate(CDCContext ctx) {
        System.debug(LoggingLevel.INFO, 'UHT Account UPDATE: ' + ctx.recordId);
    }
}
