/**
 * UHT_TriggerDeploymentService_Test
 *
 * Test coverage for the trigger deployment service that orchestrates
 * Metadata API deployments.
 */
@isTest
private class UHT_TriggerDeploymentService_Test {
  /**
   * Mock for Metadata API deploy callout
   */
  private class MetadataDeployMock implements WebServiceMock {
    private Boolean shouldFail;

    public MetadataDeployMock() {
      this.shouldFail = false;
    }

    public MetadataDeployMock(Boolean shouldFail) {
      this.shouldFail = shouldFail;
    }

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

        if (shouldFail) {
          deployResult.done = true;
          deployResult.success = false;
          deployResult.details = new MetadataService.DeployDetails();
          MetadataService.DeployMessage failureMessage = new MetadataService.DeployMessage();
          failureMessage.fullName = 'TestTrigger';
          failureMessage.problem = 'Compilation error';
          deployResult.details.componentFailures = new List<MetadataService.DeployMessage>{
            failureMessage
          };
        } else {
          deployResult.done = true;
          deployResult.success = true;
        }

        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }

  /**
   * Mock for in-progress deployment status
   */
  private class MetadataDeployInProgressMock implements WebServiceMock {
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
        deployResult.done = false;
        deployResult.success = false;
        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }

  // =========================================================================
  // deployTriggerWithSession Tests
  // =========================================================================

  @isTest
  static void testDeployTriggerWithSession_Success() {
    Test.setMock(WebServiceMock.class, new MetadataDeployMock());

    Test.startTest();
    Id logId = UHT_TriggerDeploymentService.deployTriggerWithSession(
      'Account',
      'mock-session-id'
    );
    Test.stopTest();

    System.assertNotEquals(null, logId, 'Should return deployment log ID');

    missionsf__UHT_Deployment_Log__c log = [
      SELECT
        missionsf__Object_Name__c,
        missionsf__Trigger_Name__c,
        missionsf__Status__c,
        missionsf__Deployment_Id__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :logId
      WITH USER_MODE
    ];

    System.assertEquals(
      'Account',
      log.missionsf__Object_Name__c,
      'Object name should be set'
    );
    System.assertEquals(
      'UHTAccountTrigger',
      log.missionsf__Trigger_Name__c,
      'Trigger name should be set'
    );
    System.assertEquals(
      '0Af000000000001AAA',
      log.missionsf__Deployment_Id__c,
      'Deployment ID should be set'
    );
  }

  @isTest
  static void testDeployTriggerWithSession_BlankObjectName() {
    Test.startTest();
    try {
      UHT_TriggerDeploymentService.deployTriggerWithSession(
        '',
        'mock-session-id'
      );
      System.assert(false, 'Should have thrown exception');
    } catch (UHT_TriggerDeploymentService.DeploymentException e) {
      System.assertEquals(
        'Object API name is required',
        e.getMessage(),
        'Should throw correct error'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testDeployTriggerWithSession_NullObjectName() {
    Test.startTest();
    try {
      UHT_TriggerDeploymentService.deployTriggerWithSession(
        null,
        'mock-session-id'
      );
      System.assert(false, 'Should have thrown exception');
    } catch (UHT_TriggerDeploymentService.DeploymentException e) {
      System.assertEquals(
        'Object API name is required',
        e.getMessage(),
        'Should throw correct error'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testDeployTriggerWithSession_BlankSessionId() {
    Test.startTest();
    try {
      UHT_TriggerDeploymentService.deployTriggerWithSession('Account', '');
      System.assert(false, 'Should have thrown exception');
    } catch (UHT_TriggerDeploymentService.DeploymentException e) {
      System.assertEquals(
        'Session ID is required',
        e.getMessage(),
        'Should throw correct error'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testDeployTriggerWithSession_NullSessionId() {
    Test.startTest();
    try {
      UHT_TriggerDeploymentService.deployTriggerWithSession('Account', null);
      System.assert(false, 'Should have thrown exception');
    } catch (UHT_TriggerDeploymentService.DeploymentException e) {
      System.assertEquals(
        'Session ID is required',
        e.getMessage(),
        'Should throw correct error'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testDeployTriggerWithSession_TriggerAlreadyExists() {
    // Create a successful deployment log to simulate existing trigger
    missionsf__UHT_Deployment_Log__c existingLog = new missionsf__UHT_Deployment_Log__c(
      missionsf__Object_Name__c = 'Contact',
      missionsf__Trigger_Name__c = 'UHT_Contact_Trigger',
      missionsf__Status__c = 'Success',
      missionsf__Deployment_Id__c = '0Af000000000002AAA'
    );
    insert existingLog;

    Test.startTest();
    try {
      UHT_TriggerDeploymentService.deployTriggerWithSession(
        'Contact',
        'mock-session-id'
      );
      System.assert(false, 'Should have thrown exception');
    } catch (UHT_TriggerDeploymentService.DeploymentException e) {
      System.assert(
        e.getMessage().contains('Trigger already exists'),
        'Should throw trigger exists error'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testDeployTriggerWithSession_CustomObject() {
    Test.setMock(WebServiceMock.class, new MetadataDeployMock());

    Test.startTest();
    Id logId = UHT_TriggerDeploymentService.deployTriggerWithSession(
      'Custom_Object__c',
      'mock-session-id'
    );
    Test.stopTest();

    missionsf__UHT_Deployment_Log__c log = [
      SELECT missionsf__Trigger_Name__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :logId
      WITH USER_MODE
    ];

    System.assertEquals(
      'UHTCustomObjectTrigger',
      log.missionsf__Trigger_Name__c,
      'Should handle custom object naming'
    );
  }

  // =========================================================================
  // getDeploymentStatus Tests
  // =========================================================================

  @isTest
  static void testGetDeploymentStatus_Success() {
    missionsf__UHT_Deployment_Log__c log = new missionsf__UHT_Deployment_Log__c(
      missionsf__Object_Name__c = 'Account',
      missionsf__Trigger_Name__c = 'UHT_Account_Trigger',
      missionsf__Status__c = 'Success',
      missionsf__Deployment_Id__c = '0Af000000000003AAA',
      missionsf__Initiated_At__c = Datetime.now().addMinutes(-5),
      missionsf__Completed_At__c = Datetime.now()
    );
    insert log;

    Test.startTest();
    Map<String, Object> status = UHT_TriggerDeploymentService.getDeploymentStatus(
      log.Id
    );
    Test.stopTest();

    System.assertEquals(
      'Account',
      status.get('objectName'),
      'Should return object name'
    );
    System.assertEquals(
      'UHT_Account_Trigger',
      status.get('triggerName'),
      'Should return trigger name'
    );
    System.assertEquals(
      'Success',
      status.get('status'),
      'Should return status'
    );
    System.assertEquals(
      '0Af000000000003AAA',
      status.get('deploymentId'),
      'Should return deployment ID'
    );
    System.assertNotEquals(
      null,
      status.get('initiatedAt'),
      'Should return initiated timestamp'
    );
    System.assertNotEquals(
      null,
      status.get('completedAt'),
      'Should return completed timestamp'
    );
  }

  @isTest
  static void testGetDeploymentStatus_WithError() {
    missionsf__UHT_Deployment_Log__c log = new missionsf__UHT_Deployment_Log__c(
      missionsf__Object_Name__c = 'Lead',
      missionsf__Trigger_Name__c = 'UHT_Lead_Trigger',
      missionsf__Status__c = 'Failed',
      missionsf__Error_Message__c = 'Compilation error on line 5',
      missionsf__Deployment_Id__c = '0Af000000000004AAA'
    );
    insert log;

    Test.startTest();
    Map<String, Object> status = UHT_TriggerDeploymentService.getDeploymentStatus(
      log.Id
    );
    Test.stopTest();

    System.assertEquals(
      'Failed',
      status.get('status'),
      'Should return failed status'
    );
    System.assertEquals(
      'Compilation error on line 5',
      status.get('errorMessage'),
      'Should return error message'
    );
  }

  @isTest
  static void testGetDeploymentStatus_InProgress() {
    missionsf__UHT_Deployment_Log__c log = new missionsf__UHT_Deployment_Log__c(
      missionsf__Object_Name__c = 'Opportunity',
      missionsf__Trigger_Name__c = 'UHT_Opportunity_Trigger',
      missionsf__Status__c = 'In Progress',
      missionsf__Deployment_Id__c = '0Af000000000005AAA',
      missionsf__Initiated_At__c = Datetime.now()
    );
    insert log;

    Test.startTest();
    Map<String, Object> status = UHT_TriggerDeploymentService.getDeploymentStatus(
      log.Id
    );
    Test.stopTest();

    System.assertEquals(
      'In Progress',
      status.get('status'),
      'Should return in progress status'
    );
    System.assertEquals(
      null,
      status.get('completedAt'),
      'Completed timestamp should be null'
    );
  }

  // =========================================================================
  // checkDeployStatus Tests
  // =========================================================================

  @isTest
  static void testCheckDeployStatus_Success() {
    Test.setMock(WebServiceMock.class, new MetadataDeployMock());

    Test.startTest();
    MetadataService.DeployResult result = UHT_TriggerDeploymentService.checkDeployStatus(
      'mock-deployment-id',
      'mock-session-id'
    );
    Test.stopTest();

    System.assertEquals(true, result.done, 'Deployment should be done');
    System.assertEquals(
      true,
      result.success,
      'Deployment should be successful'
    );
  }

  @isTest
  static void testCheckDeployStatus_Failed() {
    Test.setMock(WebServiceMock.class, new MetadataDeployMock(true));

    Test.startTest();
    MetadataService.DeployResult result = UHT_TriggerDeploymentService.checkDeployStatus(
      'mock-deployment-id',
      'mock-session-id'
    );
    Test.stopTest();

    System.assertEquals(true, result.done, 'Deployment should be done');
    System.assertEquals(false, result.success, 'Deployment should have failed');
    System.assertNotEquals(
      null,
      result.details.componentFailures,
      'Should have failure details'
    );
  }

  @isTest
  static void testCheckDeployStatus_InProgress() {
    Test.setMock(WebServiceMock.class, new MetadataDeployInProgressMock());

    Test.startTest();
    MetadataService.DeployResult result = UHT_TriggerDeploymentService.checkDeployStatus(
      'mock-deployment-id',
      'mock-session-id'
    );
    Test.stopTest();

    System.assertEquals(false, result.done, 'Deployment should not be done');
  }

  // =========================================================================
  // deployTriggerForObject Tests (AuraEnabled wrapper)
  // =========================================================================

  @isTest
  static void testDeployTriggerForObject_BlankInput() {
    // Test the AuraEnabled wrapper with blank input
    Test.startTest();
    try {
      UHT_TriggerDeploymentService.deployTriggerForObject('');
      System.assert(false, 'Should have thrown exception');
    } catch (UHT_TriggerDeploymentService.DeploymentException e) {
      System.assertEquals(
        'Object API name is required',
        e.getMessage(),
        'Should throw correct error'
      );
    }
    Test.stopTest();
  }

  // =========================================================================
  // DeploymentException Tests
  // =========================================================================

  @isTest
  static void testDeploymentException_Construction() {
    Test.startTest();
    UHT_TriggerDeploymentService.DeploymentException ex = new UHT_TriggerDeploymentService.DeploymentException(
      'Test error message'
    );
    Test.stopTest();

    System.assertEquals(
      'Test error message',
      ex.getMessage(),
      'Exception should contain message'
    );
  }
}
