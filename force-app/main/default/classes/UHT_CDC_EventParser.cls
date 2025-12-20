public with sharing class UHT_CDC_EventParser {

    public static Map<String, Object> toPayloadMap(SObject eventRecord) {
        Map<String, Object> payload = new Map<String, Object>();
        if (eventRecord == null) {
            return payload;
        }

        // CDC change events show all fields as normal SObject fields
        Map<String, Object> flat = eventRecord.getPopulatedFieldsAsMap();
        payload.putAll(flat);

        return payload;
    }
}
