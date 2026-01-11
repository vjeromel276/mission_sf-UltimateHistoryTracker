# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ultimate History Tracker (UHT) is a Salesforce Second-Generation Managed Package (2GP) for the AppExchange that provides configurable field history tracking beyond Salesforce's native 20-field limit. It dynamically generates and deploys triggers for tracked objects, stores field changes in a custom object, and provides an admin UI for configuration.

**Namespace:** `missionsf`
**API Version:** 65.0
**Package Type:** Managed

## Development Commands

```bash
# Lint JavaScript (LWC/Aura)
npm run lint

# Run all LWC unit tests
npm run test:unit

# Run tests in watch mode
npm run test:unit:watch

# Run a single test file
npx sfdx-lwc-jest --testPathPattern="uhtAdminConsole.test.js"

# Format code
npm run prettier

# Deploy to scratch org
sf project deploy start --source-dir force-app

# Run Apex tests in org
sf apex run test --test-level RunLocalTests --result-format human

# Run security scan (required before every commit)
sf code-analyzer run --rule-selector AppExchange --target force-app
```

## Architecture

### Core Trigger Flow
1. **UHT_TriggerHandler** - Entry point called by deployed triggers. Looks up tracking config from Custom Metadata, checks recursion, routes to sync/async processing
2. **UHT_FieldChangeDetector** - Pure comparison logic. Compares old vs new values, identifies which field types require async (Long Text Area, Rich Text)
3. **UHT_ChangeLogWriter** - Writes changes to `UHT_Change_Log__c`. Sync for single records, async (Queueable) for bulk or large text fields
4. **UHT_RecursionManager** - Prevents duplicate processing within same transaction

### Trigger Generation & Deployment
- **UHT_TriggerGenerator** - Generates trigger source code and metadata XML for target objects
- **UHT_NamingHelper** - Consistent naming conventions for generated triggers
- **UHT_TriggerDeploymentService** - Deploys triggers via Metadata API (uses Zippex for packaging)
- **UHT_DeploymentRestService** - REST endpoint for trigger deployment via Named Credential (bypasses Lightning session restrictions)
- **UHT_DeploymentStatusPoller** - Queueable that polls deployment status

### Admin UI
- **UHT_AdminController** - Apex controller providing object/field lists and save operations
- **uhtAdminConsole** LWC - Admin interface for selecting objects and fields to track

### Custom Metadata Types
- `UHT_Tracked_Object__mdt` - Which objects are tracked (ObjectApiName__c, IsActive__c)
- `UHT_Tracked_Field__mdt` - Which fields are tracked per object (ObjectApiName__c, FieldApiName__c, FieldType__c, IsActive__c)

### Custom Objects
- `UHT_Change_Log__c` - Stores field change history (Tracked_Record_Id__c, Tracked_Object__c, Tracked_Field__c, Old_Value__c, New_Value__c, Change_Timestamp__c, Commit_User_Id__c)
- `UHT_Deployment_Log__c` - Tracks trigger deployment status

## Key Implementation Details

- All Apex classes use `missionsf__` namespace prefix when referencing custom objects/fields
- Triggers are generated with pattern: `UHT_{ObjectName}_Trigger` calling `missionsf.UHT_TriggerHandler.handleAfterUpdate()`
- Custom Metadata records use sanitized names (namespace stripped, `__c` suffix removed)
- Async processing triggered when: Long Text fields change, bulk updates (>1 record), or approaching DML limits
- Trigger deployment uses Named Credential `UHT_Self_Callout` to work around Lightning session API restrictions

## Security Requirements (AppExchange)

### Apex Class Rules
1. **Every class MUST have explicit sharing declaration** (`with sharing`, `without sharing`, or `inherited sharing`)
2. **Every SOQL query MUST enforce CRUD/FLS:** Use `WITH USER_MODE`
3. **Every DML operation MUST enforce CRUD/FLS:** Use `AccessLevel.USER_MODE`
4. **SOQL Injection Prevention:** ALWAYS use bind variables (`:variableName`), NEVER concatenate user input

### LWC Rules
- NO inline JavaScript event handlers in templates
- NO `eval()` or `Function()` constructors
- External scripts MUST be loaded via Static Resources

### External Callouts
- ALL callouts MUST use HTTPS
- Use Named Credentials for authentication
