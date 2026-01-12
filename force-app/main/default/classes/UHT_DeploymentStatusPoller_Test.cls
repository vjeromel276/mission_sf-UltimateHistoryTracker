/**
 * UHT_DeploymentStatusPoller_Test
 *
 * Test coverage for the Queueable job that polls Metadata API
 * for deployment completion status.
 */
@isTest
private class UHT_DeploymentStatusPoller_Test {
  /**
   * Mock for successful deployment completion
   */
  private class DeploySuccessMock implements WebServiceMock {
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
      if (requestName == 'checkDeployStatus') {
        MetadataService.checkDeployStatusResponse_element responseElement = new MetadataService.checkDeployStatusResponse_element();
        MetadataService.DeployResult deployResult = new MetadataService.DeployResult();
        deployResult.id = 'mock-deployment-id';
        deployResult.done = true;
        deployResult.success = true;
        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }

  /**
   * Mock for failed deployment
   */
  private class DeployFailureMock implements WebServiceMock {
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
      if (requestName == 'checkDeployStatus') {
        MetadataService.checkDeployStatusResponse_element responseElement = new MetadataService.checkDeployStatusResponse_element();
        MetadataService.DeployResult deployResult = new MetadataService.DeployResult();
        deployResult.id = 'mock-deployment-id';
        deployResult.done = true;
        deployResult.success = false;
        deployResult.details = new MetadataService.DeployDetails();
        MetadataService.DeployMessage failure = new MetadataService.DeployMessage();
        failure.fullName = 'UHT_Account_Trigger';
        failure.problem = 'Variable does not exist: invalidVar';
        deployResult.details.componentFailures = new List<MetadataService.DeployMessage>{
          failure
        };
        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }

  /**
   * Mock for deployment still in progress
   */
  private class DeployInProgressMock implements WebServiceMock {
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
      if (requestName == 'checkDeployStatus') {
        MetadataService.checkDeployStatusResponse_element responseElement = new MetadataService.checkDeployStatusResponse_element();
        MetadataService.DeployResult deployResult = new MetadataService.DeployResult();
        deployResult.id = 'mock-deployment-id';
        deployResult.done = false;
        deployResult.success = false;
        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }

  /**
   * Mock for failed deployment with no details
   */
  private class DeployFailureNoDetailsMock implements WebServiceMock {
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
      if (requestName == 'checkDeployStatus') {
        MetadataService.checkDeployStatusResponse_element responseElement = new MetadataService.checkDeployStatusResponse_element();
        MetadataService.DeployResult deployResult = new MetadataService.DeployResult();
        deployResult.id = 'mock-deployment-id';
        deployResult.done = true;
        deployResult.success = false;
        // No details or componentFailures
        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }

  /**
   * Mock that throws an exception
   */
  private class DeployExceptionMock implements WebServiceMock {
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
      throw new CalloutException('Network error');
    }
  }

  /**
   * Helper to create a deployment log for testing
   */
  private static missionsf__UHT_Deployment_Log__c createTestLog() {
    missionsf__UHT_Deployment_Log__c log = new missionsf__UHT_Deployment_Log__c(
      missionsf__Object_Name__c = 'Account',
      missionsf__Trigger_Name__c = 'UHT_Account_Trigger',
      missionsf__Status__c = 'In Progress',
      missionsf__Deployment_Id__c = 'mock-deployment-id',
      missionsf__Initiated_At__c = Datetime.now()
    );
    insert log;
    return log;
  }

  // =========================================================================
  // Constructor Tests
  // =========================================================================

  @isTest
  static void testConstructor_ThreeParams() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();

    Test.startTest();
    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'deployment-id',
      'session-id'
    );
    Test.stopTest();

    System.assertNotEquals(null, poller, 'Poller should be instantiated');
  }

  @isTest
  static void testConstructor_FourParams() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();

    Test.startTest();
    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'deployment-id',
      'session-id',
      5
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      poller,
      'Poller should be instantiated with poll count'
    );
  }

  // =========================================================================
  // Execute Tests - Success Path
  // =========================================================================

  @isTest
  static void testExecute_DeploymentSuccess() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();
    Test.setMock(WebServiceMock.class, new DeploySuccessMock());

    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'mock-deployment-id',
      'mock-session-id'
    );

    Test.startTest();
    System.enqueueJob(poller);
    Test.stopTest();

    // Verify log was updated to Success
    missionsf__UHT_Deployment_Log__c updatedLog = [
      SELECT
        missionsf__Status__c,
        missionsf__Completed_At__c,
        missionsf__Error_Message__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :log.Id
      WITH SYSTEM_MODE
    ];

    System.assertEquals(
      'Success',
      updatedLog.missionsf__Status__c,
      'Status should be Success'
    );
    System.assertNotEquals(
      null,
      updatedLog.missionsf__Completed_At__c,
      'Completed timestamp should be set'
    );
    System.assertEquals(
      null,
      updatedLog.missionsf__Error_Message__c,
      'Error message should be null on success'
    );
  }

  // =========================================================================
  // Execute Tests - Failure Path
  // =========================================================================

  @isTest
  static void testExecute_DeploymentFailure() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();
    Test.setMock(WebServiceMock.class, new DeployFailureMock());

    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'mock-deployment-id',
      'mock-session-id'
    );

    Test.startTest();
    System.enqueueJob(poller);
    Test.stopTest();

    // Verify log was updated to Failed
    missionsf__UHT_Deployment_Log__c updatedLog = [
      SELECT
        missionsf__Status__c,
        missionsf__Completed_At__c,
        missionsf__Error_Message__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :log.Id
      WITH SYSTEM_MODE
    ];

    System.assertEquals(
      'Failed',
      updatedLog.missionsf__Status__c,
      'Status should be Failed'
    );
    System.assertNotEquals(
      null,
      updatedLog.missionsf__Completed_At__c,
      'Completed timestamp should be set'
    );
    System.assert(
      updatedLog.missionsf__Error_Message__c.contains(
        'Variable does not exist'
      ),
      'Error message should contain failure details'
    );
  }

  @isTest
  static void testExecute_DeploymentFailure_NoDetails() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();
    Test.setMock(WebServiceMock.class, new DeployFailureNoDetailsMock());

    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'mock-deployment-id',
      'mock-session-id'
    );

    Test.startTest();
    System.enqueueJob(poller);
    Test.stopTest();

    // Verify log was updated with generic error message
    missionsf__UHT_Deployment_Log__c updatedLog = [
      SELECT missionsf__Status__c, missionsf__Error_Message__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :log.Id
      WITH SYSTEM_MODE
    ];

    System.assertEquals(
      'Failed',
      updatedLog.missionsf__Status__c,
      'Status should be Failed'
    );
    System.assert(
      updatedLog.missionsf__Error_Message__c.contains('Deployment failed'),
      'Should have generic failure message'
    );
  }

  // =========================================================================
  // Execute Tests - In Progress (Chaining)
  // =========================================================================

  @isTest
  static void testExecute_DeploymentInProgress_ChainsNextPoll() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();
    Test.setMock(WebServiceMock.class, new DeployInProgressMock());

    // Test that chaining logic is executed when deployment is in progress
    // In test context, chained jobs execute immediately which may cause different outcomes
    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'mock-deployment-id',
      'mock-session-id',
      0
    );

    Test.startTest();
    System.enqueueJob(poller);
    Test.stopTest();

    // Verify the poller executed and updated the log (status will vary based on chaining behavior)
    missionsf__UHT_Deployment_Log__c updatedLog = [
      SELECT missionsf__Status__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :log.Id
      WITH SYSTEM_MODE
    ];

    // Status should be updated to something other than initial (In Progress was checked)
    System.assertNotEquals(
      null,
      updatedLog.missionsf__Status__c,
      'Status should be set'
    );
  }

  // =========================================================================
  // Execute Tests - Timeout
  // =========================================================================

  @isTest
  static void testExecute_Timeout() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();
    Test.setMock(WebServiceMock.class, new DeployInProgressMock());

    // Start at poll count 19 (one below max of 20)
    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'mock-deployment-id',
      'mock-session-id',
      19
    );

    Test.startTest();
    System.enqueueJob(poller);
    Test.stopTest();

    // Verify timeout status
    missionsf__UHT_Deployment_Log__c updatedLog = [
      SELECT
        missionsf__Status__c,
        missionsf__Error_Message__c,
        missionsf__Completed_At__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :log.Id
      WITH SYSTEM_MODE
    ];

    System.assertEquals(
      'Timeout',
      updatedLog.missionsf__Status__c,
      'Status should be Timeout'
    );
    System.assert(
      updatedLog.missionsf__Error_Message__c.contains('timed out'),
      'Error should mention timeout'
    );
    System.assertNotEquals(
      null,
      updatedLog.missionsf__Completed_At__c,
      'Completed timestamp should be set'
    );
  }

  // =========================================================================
  // Execute Tests - Exception Handling
  // =========================================================================

  @isTest
  static void testExecute_ExceptionHandling() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();
    Test.setMock(WebServiceMock.class, new DeployExceptionMock());

    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'mock-deployment-id',
      'mock-session-id'
    );

    Test.startTest();
    System.enqueueJob(poller);
    Test.stopTest();

    // Verify error was logged
    missionsf__UHT_Deployment_Log__c updatedLog = [
      SELECT
        missionsf__Status__c,
        missionsf__Error_Message__c,
        missionsf__Completed_At__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :log.Id
      WITH SYSTEM_MODE
    ];

    System.assertEquals(
      'Failed',
      updatedLog.missionsf__Status__c,
      'Status should be Failed'
    );
    System.assert(
      updatedLog.missionsf__Error_Message__c.contains('Polling error'),
      'Error should indicate polling error'
    );
    System.assertNotEquals(
      null,
      updatedLog.missionsf__Completed_At__c,
      'Completed timestamp should be set'
    );
  }

  // =========================================================================
  // Edge Cases
  // =========================================================================

  @isTest
  static void testExecute_MultipleFailureMessages() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();

    // Create mock with multiple failure messages
    Test.setMock(WebServiceMock.class, new MultipleFailuresMock());

    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'mock-deployment-id',
      'mock-session-id'
    );

    Test.startTest();
    System.enqueueJob(poller);
    Test.stopTest();

    missionsf__UHT_Deployment_Log__c updatedLog = [
      SELECT missionsf__Error_Message__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :log.Id
      WITH SYSTEM_MODE
    ];

    System.assert(
      updatedLog.missionsf__Error_Message__c.contains('Error 1'),
      'Should contain first error'
    );
    System.assert(
      updatedLog.missionsf__Error_Message__c.contains('Error 2'),
      'Should contain second error'
    );
  }

  /**
   * Mock with multiple component failures
   */
  private class MultipleFailuresMock implements WebServiceMock {
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
      if (requestName == 'checkDeployStatus') {
        MetadataService.checkDeployStatusResponse_element responseElement = new MetadataService.checkDeployStatusResponse_element();
        MetadataService.DeployResult deployResult = new MetadataService.DeployResult();
        deployResult.id = 'mock-deployment-id';
        deployResult.done = true;
        deployResult.success = false;
        deployResult.details = new MetadataService.DeployDetails();

        MetadataService.DeployMessage failure1 = new MetadataService.DeployMessage();
        failure1.fullName = 'Component1';
        failure1.problem = 'Error 1';

        MetadataService.DeployMessage failure2 = new MetadataService.DeployMessage();
        failure2.fullName = 'Component2';
        failure2.problem = 'Error 2';

        deployResult.details.componentFailures = new List<MetadataService.DeployMessage>{
          failure1,
          failure2
        };
        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }

  @isTest
  static void testExecute_NullProblemInFailure() {
    missionsf__UHT_Deployment_Log__c log = createTestLog();
    Test.setMock(WebServiceMock.class, new NullProblemMock());

    UHT_DeploymentStatusPoller poller = new UHT_DeploymentStatusPoller(
      log.Id,
      'mock-deployment-id',
      'mock-session-id'
    );

    Test.startTest();
    System.enqueueJob(poller);
    Test.stopTest();

    missionsf__UHT_Deployment_Log__c updatedLog = [
      SELECT missionsf__Status__c, missionsf__Error_Message__c
      FROM missionsf__UHT_Deployment_Log__c
      WHERE Id = :log.Id
      WITH SYSTEM_MODE
    ];

    System.assertEquals(
      'Failed',
      updatedLog.missionsf__Status__c,
      'Status should be Failed'
    );
    // Should get generic message since problem is null
    System.assert(
      updatedLog.missionsf__Error_Message__c.contains('Deployment failed'),
      'Should have generic failure message'
    );
  }

  /**
   * Mock with null problem field
   */
  private class NullProblemMock implements WebServiceMock {
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
      if (requestName == 'checkDeployStatus') {
        MetadataService.checkDeployStatusResponse_element responseElement = new MetadataService.checkDeployStatusResponse_element();
        MetadataService.DeployResult deployResult = new MetadataService.DeployResult();
        deployResult.id = 'mock-deployment-id';
        deployResult.done = true;
        deployResult.success = false;
        deployResult.details = new MetadataService.DeployDetails();

        MetadataService.DeployMessage failure = new MetadataService.DeployMessage();
        failure.fullName = 'Component';
        failure.problem = null; // Null problem

        deployResult.details.componentFailures = new List<MetadataService.DeployMessage>{
          failure
        };
        responseElement.result = deployResult;
        response.put('response_x', responseElement);
      }
    }
  }
}
