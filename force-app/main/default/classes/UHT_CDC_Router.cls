public with sharing class UHT_CDC_Router {

    public static void route(List<SObject> events) {
        if (events == null || events.isEmpty()) {
            return;
        }

        SObject first = events[0];
        String typeName = first.getSObjectType().getDescribe().getName();
        // Example: 'AccountChangeEvent' -> 'Account'
        String entityName = typeName.removeEnd('ChangeEvent');

        String handlerClassName = 'UHT_' + entityName + '_CDC_Handler';

        Type handlerType = Type.forName(handlerClassName);
        if (handlerType == null) {
            // No handler for this object – silently skip
            return;
        }

        UHT_CDC_Handler handler = (UHT_CDC_Handler) handlerType.newInstance();

        for (SObject e : events) {
            Map<String, Object> payload = UHT_CDC_EventParser.toPayloadMap(e);
            UHT_CDC_Handler.CDCContext ctx = new UHT_CDC_Handler.CDCContext(payload);
            handler.handle(ctx);
        }
    }
}
