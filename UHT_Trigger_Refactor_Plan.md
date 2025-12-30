# UHT Trigger-Based Field Tracking - Refactoring Plan

## Current Repository Inventory

### Apex Classes

| File | Status | Notes |
|------|--------|-------|
| `UHT_AdminController.cls` | **MODIFY** | Remove CDC references, add FieldType__c to metadata creation |
| `UHT_TriggerGenerator.cls` | **MODIFY** | Change template from CDC trigger to standard after update trigger |
| `UHT_TriggerDeploymentService.cls` | **MODIFY** | Update comments, remove CDC-specific references |
| `UHT_DeploymentRestService.cls` | **MODIFY** | Remove getCDCEnabledObjects() method |
| `UHT_DeploymentStatusPoller.cls` | KEEP | No changes needed |
| `UHT_NamingHelper.cls` | **MODIFY** | Remove ChangeEvent naming methods, add standard trigger naming |
| `UHT_NamingHelper_Test.cls` | **MODIFY** | Update tests for new naming conventions |
| `MetadataService.cls` | KEEP | Third-party library, no changes |
| `Zippex.cls` | KEEP | Third-party library, no changes |
| `HexUtil.cls` | KEEP | Dependency of Zippex |

### New Apex Classes to Create

| File | Purpose |
|------|---------|
| `UHT_TriggerHandler.cls` | Entry point from deployed triggers, owns config lookup, routes to sync/async |
| `UHT_RecursionManager.cls` | Static map tracking processed record IDs per operation type |
| `UHT_FieldChangeDetector.cls` | Pure comparison logic - receives field list, compares old/new values |
| `UHT_ChangeLogWriter.cls` | Sync and async (Queueable) methods to write UHT_Change_Log__c records |
| `UHT_TriggerHandler_Test.cls` | Unit tests for handler |
| `UHT_RecursionManager_Test.cls` | Unit tests for recursion control |
| `UHT_FieldChangeDetector_Test.cls` | Unit tests for field comparison |
| `UHT_ChangeLogWriter_Test.cls` | Unit tests for sync/async writing |

### Custom Objects

| Object | Status | Notes |
|--------|--------|-------|
| `UHT_Change_Log__c` | KEEP | No changes needed |
| `UHT_Deployment_Log__c` | KEEP | No changes needed |
| `UHT_Tracked_Object__mdt` | KEEP | No changes needed |
| `UHT_Tracked_Field__mdt` | **MODIFY** | Add FieldType__c field |

### UHT_Change_Log__c Fields (verified)

| Field | Type | Notes |
|-------|------|-------|
| `Name` | AutoNumber | Format: UHT-{00000} |
| `Tracked_Record_Id__c` | Text(18) | Required - ID of the record that changed |
| `Tracked_Object__c` | Text(80) | Required - Object API name |
| `Tracked_Field__c` | Text(80) | Required - Field API name |
| `Old_Value__c` | Long Text Area | 131072 chars |
| `New_Value__c` | Long Text Area | 131072 chars |
| `Change_Type__c` | Picklist | CREATE, UPDATE, DELETE, UNDELETE |
| `Change_Timestamp__c` | DateTime | When the change occurred |
| `Commit_User_Id__c` | Text(18) | Required - User who made the change |

**Status: Schema is complete for trigger-based tracking. No additional fields needed.**

### UHT_Tracked_Field__mdt Fields

| Field | Status | Notes |
|-------|--------|-------|
| `ObjectApiName__c` | KEEP | Text(80), SubscriberControlled |
| `FieldApiName__c` | KEEP | Text(80), SubscriberControlled |
| `IsActive__c` | KEEP | Checkbox, SubscriberControlled |
| `FieldType__c` | **ADD** | Text(40), SubscriberControlled - stores DisplayType name |

### LWC Components

| Component | Status | Notes |
|-----------|--------|-------|
| `uhtAdminConsole.html` | **MODIFY** | Remove CDC capability indicators, update messaging |
| `uhtAdminConsole.js` | **MODIFY** | Remove cdcEnabled references, send field type on save |
| `uhtAdminConsole.css` | **MODIFY** | Remove CDC-related styles |
| `uhtAdminConsole.test.js` | **MODIFY** | Update tests |

### Other Files

| File | Status | Notes |
|------|--------|-------|
| Layouts | KEEP | No changes needed |
| Permission Sets | KEEP | No changes needed |
| Named Credential | KEEP | Still used for trigger deployment |
| Auth Provider | KEEP | Still used for trigger deployment |

---

## Phased Execution Plan

### Phase 1: Schema Updates
**Goal:** Add required metadata field

| Step | Task | Verification |
|------|------|--------------|
| 1.1 | Deploy `FieldType__c` to `UHT_Tracked_Field__mdt` | Field visible in Setup |
| 1.2 | ~~Verify `UHT_Change_Log__c` fields~~ | ✅ Already verified - has all required fields |

---

### Phase 2: Core Handler Classes (New)
**Goal:** Build the trigger processing backbone

| Step | Task | Verification |
|------|------|--------------|
| 2.1 | Create `UHT_RecursionManager.cls` | Compile success |
| 2.2 | Create `UHT_RecursionManager_Test.cls` | Tests pass |
| 2.3 | Create `UHT_FieldChangeDetector.cls` | Compile success |
| 2.4 | Create `UHT_FieldChangeDetector_Test.cls` | Tests pass |
| 2.5 | Create `UHT_ChangeLogWriter.cls` (sync + Queueable) | Compile success |
| 2.6 | Create `UHT_ChangeLogWriter_Test.cls` | Tests pass |
| 2.7 | Create `UHT_TriggerHandler.cls` (orchestrator) | Compile success |
| 2.8 | Create `UHT_TriggerHandler_Test.cls` | Tests pass |

---

### Phase 3: Modify Existing Classes
**Goal:** Update generator and helpers for standard triggers

| Step | Task | Verification |
|------|------|--------------|
| 3.1 | Modify `UHT_NamingHelper.cls` - remove ChangeEvent methods, add standard trigger naming | Compile success |
| 3.2 | Update `UHT_NamingHelper_Test.cls` | Tests pass |
| 3.3 | Modify `UHT_TriggerGenerator.cls` - new template for `after update` trigger | Compile success |
| 3.4 | Create/update `UHT_TriggerGenerator_Test.cls` | Tests pass |
| 3.5 | Modify `UHT_TriggerDeploymentService.cls` - update comments only | Compile success |
| 3.6 | Modify `UHT_DeploymentRestService.cls` - remove getCDCEnabledObjects() | Compile success |

---

### Phase 4: Admin Controller & UI Updates
**Goal:** Update configuration flow to use new approach

| Step | Task | Verification |
|------|------|--------------|
| 4.1 | Modify `UHT_AdminController.cls` - remove CDC checks, add FieldType__c to metadata deploy | Compile success |
| 4.2 | Update `UHT_AdminController_Test.cls` (if exists) | Tests pass |
| 4.3 | Modify `uhtAdminConsole.html` - remove CDC indicators | Visual verification |
| 4.4 | Modify `uhtAdminConsole.js` - remove cdcEnabled, pass field type | Console log verification |
| 4.5 | Modify `uhtAdminConsole.css` - remove CDC styles | Visual verification |

---

### Phase 5: Integration Testing
**Goal:** End-to-end validation

| Step | Task | Verification |
|------|------|--------------|
| 5.1 | Deploy all changes to scratch org | Deployment success |
| 5.2 | Configure tracking for Account object with 2-3 fields via UI | Metadata records created |
| 5.3 | Verify trigger deployed successfully | Trigger visible in Setup |
| 5.4 | Update single Account record | UHT_Change_Log__c record created |
| 5.5 | Bulk update 5 Account records | UHT_Change_Log__c records created (async) |
| 5.6 | Update Account with Long Text field | Async processing confirmed |
| 5.7 | Trigger workflow/flow re-fire scenario | Recursion control working |

---

### Phase 6: Cleanup & Documentation
**Goal:** Remove dead code, update docs

| Step | Task | Verification |
|------|------|--------------|
| 6.1 | Remove any CDC-only classes if they exist (UHT_CDC_Router, etc.) | No compile errors |
| 6.2 | Update README.md | Accurate documentation |
| 6.3 | Update any inline documentation | Review complete |
| 6.4 | Run full test suite | 100% pass, adequate coverage |

---

## Files Summary

### To Create (9 files)
1. `UHT_TriggerHandler.cls`
2. `UHT_TriggerHandler_Test.cls`
3. `UHT_RecursionManager.cls`
4. `UHT_RecursionManager_Test.cls`
5. `UHT_FieldChangeDetector.cls`
6. `UHT_FieldChangeDetector_Test.cls`
7. `UHT_ChangeLogWriter.cls`
8. `UHT_ChangeLogWriter_Test.cls`
9. `FieldType__c.field-meta.xml` (already created)

### To Modify (10 files)
1. `UHT_AdminController.cls`
2. `UHT_TriggerGenerator.cls`
3. `UHT_TriggerDeploymentService.cls`
4. `UHT_DeploymentRestService.cls`
5. `UHT_NamingHelper.cls`
6. `UHT_NamingHelper_Test.cls`
7. `uhtAdminConsole.html`
8. `uhtAdminConsole.js`
9. `uhtAdminConsole.css`
10. `UHT_Tracked_Field__mdt` (via FieldType__c)

### To Keep Unchanged (10+ files)
- `MetadataService.cls`
- `Zippex.cls`
- `HexUtil.cls`
- `UHT_DeploymentStatusPoller.cls`
- `UHT_Change_Log__c` and its fields
- `UHT_Deployment_Log__c` and its fields
- `UHT_Tracked_Object__mdt`
- All layouts
- Named Credential / Auth Provider configs

---

## Open Questions Before Starting

1. ~~**UHT_Change_Log__c fields**~~ ✅ **VERIFIED** - Has all required fields: `Tracked_Object__c`, `Tracked_Field__c`, `New_Value__c`, `Commit_User_Id__c`, `Change_Timestamp__c`

2. **Namespace handling** - The current code uses `missionsf` namespace. Confirm this is correct for the new branch.

3. **UHT_CDC_Router** - I didn't find this class in the project knowledge. Was it already removed, or does it exist under a different name? This is good - means less cleanup needed.

4. **Global vs Public** - `UHT_TriggerHandler` must be `global` for cross-namespace calls from subscriber triggers. Confirm this aligns with packaging strategy.
