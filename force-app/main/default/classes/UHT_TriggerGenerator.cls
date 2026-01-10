/**
 * UHT_TriggerGenerator
 * 
 * Generates trigger source code and metadata for deployment.
 */
public with sharing class UHT_TriggerGenerator {

    public class TriggerFiles {
        public String triggerCode;
        public String metaXml;
        public String triggerName;
        
        public TriggerFiles(String name, String code, String xml) {
            this.triggerName = name;
            this.triggerCode = code;
            this.metaXml = xml;
        }
    }

    private static final String API_VERSION = '65.0';

    // Namespace prefix for packaged handler class
    private static final String NAMESPACE = 'missionsf';

    /**
     * Generate trigger files for a given object
     * @param objectApiName The API name of the object (e.g., 'Contact', 'Opportunity', 'Custom_Object__c')
     * @return TriggerFiles containing triggerName, triggerCode, and metaXml
     */
    public static TriggerFiles generate(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new TriggerGeneratorException('Object API name is required');
        }

        // Sanitize input - remove any whitespace
        objectApiName = objectApiName.trim();

        String triggerName = UHT_NamingHelper.getTriggerName(objectApiName);

        String triggerCode = generateTriggerCode(triggerName, objectApiName);
        String metaXml = generateMetaXml();

        return new TriggerFiles(triggerName, triggerCode, metaXml);
    }

    /**
     * Generate the trigger source code
     */
    private static String generateTriggerCode(String triggerName, String objectApiName) {
        String triggerCode = 'trigger ' + triggerName + ' on ' + objectApiName + ' (after update) {\n'
             + '    ' + NAMESPACE + '.UHT_TriggerHandler.handleAfterUpdate(\'' + objectApiName + '\', Trigger.new, Trigger.oldMap);\n'
             + '}';
        System.debug('Generated trigger code:\\n' + triggerCode);
        return triggerCode;
    }

    /**
     * Generate the trigger metadata XML
     */
    private static String generateMetaXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>\n'
             + '<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">\n'
             + '    <apiVersion>' + API_VERSION + '</apiVersion>\n'
             + '    <status>Active</status>\n'
             + '</ApexTrigger>';
    }

    public class TriggerGeneratorException extends Exception {}
}