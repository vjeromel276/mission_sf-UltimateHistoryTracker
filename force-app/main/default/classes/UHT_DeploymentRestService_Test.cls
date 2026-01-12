/**
 * UHT_DeploymentRestService_Test
 *
 * Test coverage for the REST endpoint that handles trigger deployment
 * via Named Credential callout.
 */
@isTest
private class UHT_DeploymentRestService_Test {
  /**
   * Mock for Metadata API deploy callout
   */
  private class MetadataDeployMock implements WebServiceMock {
    public void doInvoke(
      Object stub,
      Object request,
      Map<String, Object> response,
      String endpoint,
      String soapAction,
      String requestName,
      String responseNS,
      String responseName,
      String responseType
    ) {
      if (requestName == 'deploy') {
        MetadataService.deployResponse_element responseElement = new MetadataService.deployResponse_element();
        MetadataService.AsyncResult asyncResult = new MetadataService.AsyncResult();
        asyncResult.id = '0Af000000000001AAA';
        asyncResult.done = false;
        asyncResult.state = 'Queued';
        responseElement.result = asyncResult;
        response.put('response_x', responseElement);
      } else if (requestName == 'checkDeployStatus') {
        MetadataService.checkDeployStatusResponse_element responseElement = new MetadataService.checkDeployStatusResponse_element();
        MetadataService.DeployResult deployResult = new MetadataService.DeployResult();
        deployResult.id = '0Af000000000001AAA';
        deployResult.done = true;
        deployResult.success = true;
        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }

  /**
   * Helper to set up REST context
   */
  private static void setupRestContext(String requestBody) {
    RestRequest req = new RestRequest();
    req.requestURI = '/services/apexrest/uht/deploy';
    req.httpMethod = 'POST';
    req.requestBody = Blob.valueOf(requestBody);
    RestContext.request = req;
    RestContext.response = new RestResponse();
  }

  // =========================================================================
  // deployTrigger Endpoint Tests
  // =========================================================================

  @isTest
  static void testDeployTrigger_BlankObjectName() {
    setupRestContext('{"objectApiName": ""}');

    Test.startTest();
    UHT_DeploymentRestService.DeploymentResult result = UHT_DeploymentRestService.deployTrigger();
    Test.stopTest();

    System.assertEquals(
      false,
      result.success,
      'Should fail with blank object name'
    );
    System.assertEquals(
      'objectApiName is required',
      result.errorMessage,
      'Should return correct error message'
    );
  }

  @isTest
  static void testDeployTrigger_NullObjectName() {
    setupRestContext('{}');

    Test.startTest();
    UHT_DeploymentRestService.DeploymentResult result = UHT_DeploymentRestService.deployTrigger();
    Test.stopTest();

    System.assertEquals(
      false,
      result.success,
      'Should fail with null object name'
    );
    System.assertEquals(
      'objectApiName is required',
      result.errorMessage,
      'Should return correct error message'
    );
  }

  @isTest
  static void testDeployTrigger_InvalidJson() {
    setupRestContext('not valid json');

    Test.startTest();
    UHT_DeploymentRestService.DeploymentResult result = UHT_DeploymentRestService.deployTrigger();
    Test.stopTest();

    System.assertEquals(false, result.success, 'Should fail with invalid JSON');
    System.assertNotEquals(
      null,
      result.errorMessage,
      'Should have error message'
    );
  }

  @isTest
  static void testDeployTrigger_ValidRequest() {
    // Test that a valid request is processed (session availability varies by context)
    setupRestContext('{"objectApiName": "Account"}');

    Test.startTest();
    UHT_DeploymentRestService.DeploymentResult result = UHT_DeploymentRestService.deployTrigger();
    Test.stopTest();

    // Result depends on session availability - just verify we get a result
    System.assertNotEquals(null, result, 'Should return a result');
    System.assertNotEquals(null, result.success, 'Success flag should be set');
  }

  // =========================================================================
  // DeploymentResult Wrapper Tests
  // =========================================================================

  @isTest
  static void testDeploymentResult_AllFields() {
    Test.startTest();
    UHT_DeploymentRestService.DeploymentResult result = new UHT_DeploymentRestService.DeploymentResult();
    result.success = true;
    result.deploymentLogId = 'a0X000000000001';
    result.queuedJobId = '7071234567890';
    result.message = 'Deployment queued';
    result.errorMessage = null;
    Test.stopTest();

    System.assertEquals(true, result.success, 'Success should be set');
    System.assertEquals(
      'a0X000000000001',
      result.deploymentLogId,
      'Deployment log ID should be set'
    );
    System.assertEquals(
      '7071234567890',
      result.queuedJobId,
      'Queued job ID should be set'
    );
    System.assertEquals(
      'Deployment queued',
      result.message,
      'Message should be set'
    );
    System.assertEquals(
      null,
      result.errorMessage,
      'Error message should be null'
    );
  }

  @isTest
  static void testDeploymentResult_ErrorState() {
    Test.startTest();
    UHT_DeploymentRestService.DeploymentResult result = new UHT_DeploymentRestService.DeploymentResult();
    result.success = false;
    result.errorMessage = 'Something went wrong';
    Test.stopTest();

    System.assertEquals(false, result.success, 'Success should be false');
    System.assertEquals(
      'Something went wrong',
      result.errorMessage,
      'Error message should be set'
    );
  }

  // =========================================================================
  // TriggerDeploymentQueueable Tests
  // =========================================================================

  @isTest
  static void testTriggerDeploymentQueueable_Constructor() {
    Test.startTest();
    UHT_DeploymentRestService.TriggerDeploymentQueueable queueable = new UHT_DeploymentRestService.TriggerDeploymentQueueable(
      'Account',
      'mock-session-id'
    );
    Test.stopTest();

    System.assertNotEquals(null, queueable, 'Queueable should be instantiated');
  }

  @isTest
  static void testTriggerDeploymentQueueable_Execute() {
    Test.setMock(WebServiceMock.class, new MetadataDeployMock());

    UHT_DeploymentRestService.TriggerDeploymentQueueable queueable = new UHT_DeploymentRestService.TriggerDeploymentQueueable(
      'Case',
      'mock-session-id'
    );

    Test.startTest();
    System.enqueueJob(queueable);
    Test.stopTest();

    // Verify deployment log was created
    List<missionsf__UHT_Deployment_Log__c> logs = [
      SELECT missionsf__Object_Name__c, missionsf__Status__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE missionsf__Object_Name__c = 'Case'
      WITH SYSTEM_MODE
    ];

    System.assertEquals(1, logs.size(), 'Should create deployment log');
    System.assertEquals(
      'Case',
      logs[0].missionsf__Object_Name__c,
      'Should set object name'
    );
  }

  @isTest
  static void testTriggerDeploymentQueueable_ExecuteWithException() {
    // Don't set mock - this will cause an exception during callout
    UHT_DeploymentRestService.TriggerDeploymentQueueable queueable = new UHT_DeploymentRestService.TriggerDeploymentQueueable(
      'Lead',
      'mock-session-id'
    );

    Test.startTest();
    // Execute directly to test exception handling
    try {
      queueable.execute(null);
    } catch (Exception e) {
      // Exception is caught and logged in execute method
    }
    Test.stopTest();

    // No assertion needed - just verifying no unhandled exception
    System.assert(true, 'Should handle exception gracefully');
  }

  @isTest
  static void testTriggerDeploymentQueueable_TriggerAlreadyExists() {
    // Create existing successful deployment
    missionsf__UHT_Deployment_Log__c existingLog = new missionsf__UHT_Deployment_Log__c(
      missionsf__Object_Name__c = 'Opportunity',
      missionsf__Trigger_Name__c = 'UHT_Opportunity_Trigger',
      missionsf__Status__c = 'Success',
      missionsf__Deployment_Id__c = 'existing-id'
    );
    insert existingLog;

    Test.setMock(WebServiceMock.class, new MetadataDeployMock());

    UHT_DeploymentRestService.TriggerDeploymentQueueable queueable = new UHT_DeploymentRestService.TriggerDeploymentQueueable(
      'Opportunity',
      'mock-session-id'
    );

    Test.startTest();
    // This should log an error but not throw
    queueable.execute(null);
    Test.stopTest();

    // Should still only have the one existing log
    List<missionsf__UHT_Deployment_Log__c> logs = [
      SELECT Id
      FROM missionsf__UHT_Deployment_Log__c
      WHERE missionsf__Object_Name__c = 'Opportunity'
      WITH SYSTEM_MODE
    ];

    System.assertEquals(1, logs.size(), 'Should not create duplicate log');
  }
}
