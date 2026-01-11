/**
 * UHT_AdminController_Test
 * 
 * Unit tests for UHT_AdminController.
 */
@IsTest
private class UHT_AdminController_Test {

    // =========================================================================
    // getAvailableObjects() Tests
    // =========================================================================

    @IsTest
    static void testGetAvailableObjects_ReturnsResults() {
        // Act
        Test.startTest();
        List<UHT_AdminController.ObjectInfo> results = UHT_AdminController.getAvailableObjects();
        Test.stopTest();

        // Assert - should return some objects (at minimum, standard objects like Account)
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return at least one object');

        // Verify structure of returned objects
        UHT_AdminController.ObjectInfo firstObj = results[0];
        System.assertNotEquals(null, firstObj.apiName, 'apiName should not be null');
        System.assertNotEquals(null, firstObj.label, 'label should not be null');
    }

    @IsTest
    static void testGetAvailableObjects_IncludesAccount() {
        // Act
        List<UHT_AdminController.ObjectInfo> results = UHT_AdminController.getAvailableObjects();

        // Assert - Account should be in the list
        Boolean foundAccount = false;
        for (UHT_AdminController.ObjectInfo obj : results) {
            if (obj.apiName == 'Account') {
                foundAccount = true;
                System.assertEquals(false, obj.isCustom, 'Account should not be custom');
                break;
            }
        }
        System.assert(foundAccount, 'Account should be in available objects');
    }

    @IsTest
    static void testGetAvailableObjects_SortedByLabel() {
        // Act
        List<UHT_AdminController.ObjectInfo> results = UHT_AdminController.getAvailableObjects();

        // Assert - should be sorted alphabetically by label
        if (results.size() > 1) {
            for (Integer i = 0; i < results.size() - 1; i++) {
                String label1 = results[i].label;
                String label2 = results[i + 1].label;
                if (label1 != null && label2 != null) {
                    System.assert(label1.compareTo(label2) <= 0, 
                        'Results should be sorted by label: ' + label1 + ' vs ' + label2);
                }
            }
        }
    }

    // =========================================================================
    // getObjectFields() Tests
    // =========================================================================

    @IsTest
    static void testGetObjectFields_ValidObject() {
        // Act
        Test.startTest();
        List<UHT_AdminController.FieldInfo> results = UHT_AdminController.getObjectFields('Account');
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Account should have trackable fields');

        // Verify structure
        UHT_AdminController.FieldInfo firstField = results[0];
        System.assertNotEquals(null, firstField.apiName, 'apiName should not be null');
        System.assertNotEquals(null, firstField.label, 'label should not be null');
        System.assertNotEquals(null, firstField.type, 'type should not be null');
    }

    @IsTest
    static void testGetObjectFields_IncludesNameField() {
        // Act
        List<UHT_AdminController.FieldInfo> results = UHT_AdminController.getObjectFields('Account');

        // Assert - Name field should be included
        Boolean foundName = false;
        for (UHT_AdminController.FieldInfo field : results) {
            if (field.apiName == 'Name') {
                foundName = true;
                System.assertEquals('STRING', field.type, 'Name should be STRING type');
                break;
            }
        }
        System.assert(foundName, 'Name field should be in results');
    }

    @IsTest
    static void testGetObjectFields_ExcludesSystemFields() {
        // Act
        List<UHT_AdminController.FieldInfo> results = UHT_AdminController.getObjectFields('Account');

        // Assert - System fields should be excluded
        Set<String> excludedFields = new Set<String>{
            'Id', 'IsDeleted', 'CreatedById', 'CreatedDate',
            'LastModifiedById', 'LastModifiedDate', 'SystemModstamp'
        };

        for (UHT_AdminController.FieldInfo field : results) {
            System.assert(!excludedFields.contains(field.apiName),
                'System field should be excluded: ' + field.apiName);
        }
    }

    @IsTest
    static void testGetObjectFields_BlankInput() {
        // Act & Assert
        try {
            UHT_AdminController.getObjectFields('');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assertEquals('Object API name is required', e.getMessage());
        }
    }

    @IsTest
    static void testGetObjectFields_NullInput() {
        // Act & Assert
        try {
            UHT_AdminController.getObjectFields(null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assertEquals('Object API name is required', e.getMessage());
        }
    }

    @IsTest
    static void testGetObjectFields_InvalidObject() {
        // Act & Assert
        try {
            UHT_AdminController.getObjectFields('NonExistentObject__c');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Object not found'),
                'Should indicate object not found');
        }
    }

    @IsTest
    static void testGetObjectFields_CaseInsensitive() {
        // Act - use lowercase
        List<UHT_AdminController.FieldInfo> results = UHT_AdminController.getObjectFields('account');

        // Assert - should still work
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return fields even with lowercase input');
    }

    // =========================================================================
    // getTrackedConfiguration() Tests
    // =========================================================================

    @IsTest
    static void testGetTrackedConfiguration_ReturnsStructure() {
        // Act
        Test.startTest();
        UHT_AdminController.TrackingConfiguration config = UHT_AdminController.getTrackedConfiguration();
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, config, 'Config should not be null');
        System.assertNotEquals(null, config.objects, 'Objects list should not be null');
        System.assertNotEquals(null, config.fieldsByObject, 'fieldsByObject map should not be null');
    }

    // =========================================================================
    // saveTrackedConfiguration() Tests
    // =========================================================================

    @IsTest
    static void testSaveTrackedConfiguration_NoChanges() {
        // Arrange - empty lists (no changes)
        List<String> objectsToActivate = new List<String>();
        List<String> objectsToDeactivate = new List<String>();
        Map<String, List<String>> fieldsToActivate = new Map<String, List<String>>();
        Map<String, List<String>> fieldsToDeactivate = new Map<String, List<String>>();

        // Act
        Test.startTest();
        String responseJson = UHT_AdminController.saveTrackedConfiguration(
            objectsToActivate,
            objectsToDeactivate,
            fieldsToActivate,
            fieldsToDeactivate
        );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, responseJson, 'Response should not be null');
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
        System.assert(response.containsKey('mdtDeploymentId'), 'Should have mdtDeploymentId');
    }

    @IsTest
    static void testSaveTrackedConfiguration_NullInputs() {
        // Act - pass nulls (should be handled gracefully)
        Test.startTest();
        String responseJson = UHT_AdminController.saveTrackedConfiguration(
            null,
            null,
            null,
            null
        );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, responseJson, 'Response should not be null');
    }

    @IsTest
    static void testSaveTrackedConfiguration_WithObjectActivation() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new TriggerDeploymentMock());

        List<String> objectsToActivate = new List<String>{ 'Account' };
        List<String> objectsToDeactivate = new List<String>();
        Map<String, List<String>> fieldsToActivate = new Map<String, List<String>>();
        Map<String, List<String>> fieldsToDeactivate = new Map<String, List<String>>();

        // Act
        Test.startTest();
        String responseJson = UHT_AdminController.saveTrackedConfiguration(
            objectsToActivate,
            objectsToDeactivate,
            fieldsToActivate,
            fieldsToDeactivate
        );
        Test.stopTest();

        // Assert
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
        System.assert(response.containsKey('triggerDeploymentIds'), 'Should have triggerDeploymentIds');
    }

    @IsTest
    static void testSaveTrackedConfiguration_WithFieldActivation() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new TriggerDeploymentMock());

        List<String> objectsToActivate = new List<String>();
        List<String> objectsToDeactivate = new List<String>();
        Map<String, List<String>> fieldsToActivate = new Map<String, List<String>>{
            'Account' => new List<String>{ 'Name', 'Industry' }
        };
        Map<String, List<String>> fieldsToDeactivate = new Map<String, List<String>>();

        // Act
        Test.startTest();
        String responseJson = UHT_AdminController.saveTrackedConfiguration(
            objectsToActivate,
            objectsToDeactivate,
            fieldsToActivate,
            fieldsToDeactivate
        );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, responseJson, 'Response should not be null');
    }

    @IsTest
    static void testSaveTrackedConfiguration_TriggerDeploymentError() {
        // Arrange - mock that returns error
        Test.setMock(HttpCalloutMock.class, new TriggerDeploymentErrorMock());

        List<String> objectsToActivate = new List<String>{ 'Account' };
        List<String> objectsToDeactivate = new List<String>();
        Map<String, List<String>> fieldsToActivate = new Map<String, List<String>>();
        Map<String, List<String>> fieldsToDeactivate = new Map<String, List<String>>();

        // Act
        Test.startTest();
        String responseJson = UHT_AdminController.saveTrackedConfiguration(
            objectsToActivate,
            objectsToDeactivate,
            fieldsToActivate,
            fieldsToDeactivate
        );
        Test.stopTest();

        // Assert - should capture error but not fail
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
        List<Object> errors = (List<Object>) response.get('triggerErrors');
        System.assert(errors.size() > 0, 'Should have captured trigger error');
    }

    // =========================================================================
    // Wrapper Class Tests
    // =========================================================================

    @IsTest
    static void testObjectInfoWrapper() {
        // Act
        UHT_AdminController.ObjectInfo obj = new UHT_AdminController.ObjectInfo(
            'Account',
            'Account Label',
            true,
            false
        );

        // Assert
        System.assertEquals('Account', obj.apiName);
        System.assertEquals('Account Label', obj.label);
        System.assertEquals(true, obj.isTracked);
        System.assertEquals(false, obj.isCustom);
    }

    @IsTest
    static void testFieldInfoWrapper() {
        // Act
        UHT_AdminController.FieldInfo field = new UHT_AdminController.FieldInfo(
            'Name',
            'Name Label',
            'STRING',
            false
        );

        // Assert
        System.assertEquals('Name', field.apiName);
        System.assertEquals('Name Label', field.label);
        System.assertEquals('STRING', field.type);
        System.assertEquals(false, field.isTracked);
    }

    @IsTest
    static void testTrackingConfigurationWrapper() {
        // Act
        UHT_AdminController.TrackingConfiguration config = new UHT_AdminController.TrackingConfiguration();

        // Assert
        System.assertNotEquals(null, config.objects);
        System.assertNotEquals(null, config.fieldsByObject);
        System.assertEquals(0, config.objects.size());
        System.assertEquals(0, config.fieldsByObject.size());
    }

    // =========================================================================
    // MetadataDeployCallback Test
    // =========================================================================

    @IsTest
    static void testMetadataDeployCallback_Success() {
        // Arrange
        UHT_AdminController.MetadataDeployCallback callback = new UHT_AdminController.MetadataDeployCallback();
        
        // Create mock deploy result - success
        Metadata.DeployResult result = new Metadata.DeployResult();
        // Note: status is read-only, but the callback just logs, so we test it doesn't throw
        
        // Act & Assert - should not throw
        Test.startTest();
        callback.handleResult(result, null);
        Test.stopTest();
        
        System.assert(true, 'Callback should complete without error');
    }

    // =========================================================================
    // HTTP Callout Mocks
    // =========================================================================

    /**
     * Mock for successful trigger deployment
     */
    private class TriggerDeploymentMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'success' => true,
                'deploymentLogId' => 'a00000000000001AAA',
                'queuedJobId' => '7070000000000001'
            }));
            return res;
        }
    }

    /**
     * Mock for trigger deployment error response
     */
    private class TriggerDeploymentErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'success' => false,
                'errorMessage' => 'Trigger already exists'
            }));
            return res;
        }
    }

    /**
     * Mock for HTTP error
     */
    private class TriggerDeploymentHttpErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }
}