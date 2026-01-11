# CLAUDE.md - Salesforce 2GP AppExchange Package

## Project Overview

This is a Second-Generation Managed Package (2GP) intended for sale on the Salesforce AppExchange. All code must pass Salesforce Security Review.

**Package Name:** [Your Package Name]  
**Namespace:** [yournamespace]  
**Dev Hub:** [Your Dev Hub Alias]  
**Package Type:** Managed  
**Source API Version:** 62.0

## Critical Security Requirements

CRUD/FLS violations are the **#1 reason** for Security Review failure. Follow these rules without exception.

### Apex Class Rules

1. **Every class MUST have explicit sharing declaration:**
   - `public with sharing class` - Default for all user-facing code
   - `public without sharing class` - Only with documented justification
   - `public inherited sharing class` - Utility classes only

2. **Every SOQL query MUST enforce CRUD/FLS:**
   ```apex
   // REQUIRED: Use WITH USER_MODE
   List<Account> accounts = [SELECT Id, Name FROM Account WITH USER_MODE];
   
   // Dynamic SOQL alternative
   List<Account> results = Database.query(queryString, AccessLevel.USER_MODE);
   ```

3. **Every DML operation MUST enforce CRUD/FLS:**
   ```apex
   // REQUIRED: Use AccessLevel.USER_MODE
   Database.insert(records, AccessLevel.USER_MODE);
   Database.update(records, AccessLevel.USER_MODE);
   Database.delete(records, AccessLevel.USER_MODE);
   ```

4. **SOQL Injection Prevention:**
   - NEVER concatenate user input into query strings
   - ALWAYS use bind variables (`:variableName`)
   - Use `String.escapeSingleQuotes()` for LIKE clauses
   - Whitelist allowed fields for dynamic ORDER BY

### LWC/Aura Controller Rules

All `@AuraEnabled` methods must:
- Be in a `with sharing` class
- Use `WITH USER_MODE` for queries
- Use `AccessLevel.USER_MODE` for DML
- Validate all input parameters
- Return generic error messages via `AuraHandledException`

```apex
public with sharing class MyController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account WITH USER_MODE LIMIT 100];
    }
    
    @AuraEnabled
    public static void updateRecord(Account acc) {
        if (acc.Id == null) {
            throw new AuraHandledException('Invalid record');
        }
        Database.update(acc, AccessLevel.USER_MODE);
    }
}
```

### LWC Component Rules

- NO inline JavaScript event handlers in templates
- NO `eval()` or `Function()` constructors
- External scripts MUST be loaded via Static Resources
- External API domains MUST be added to CSP Trusted Sites

### External Callouts

- ALL callouts MUST use HTTPS (never HTTP)
- Use Named Credentials for authentication (never hardcode credentials)
- Validate endpoints against an allowlist
- Set appropriate timeouts (max 120 seconds)
- Log response status only, never sensitive data

### Error Handling

- Show generic error messages to users
- Log detailed errors server-side only
- Never expose stack traces, system paths, or database schema

## Project Structure

```
force-app/
├── main/
│   └── default/
│       ├── classes/           # Apex classes
│       ├── lwc/               # Lightning Web Components
│       ├── aura/              # Aura components (if any)
│       ├── triggers/          # Apex triggers
│       ├── objects/           # Custom objects and fields
│       ├── permissionsets/    # Permission Sets
│       ├── customMetadata/    # Custom Metadata Types
│       └── staticresources/   # Static Resources
config/
├── project-scratch-def.json   # Scratch org definition
scripts/
├── run-security-scan.sh       # Security scanning script
```

## Development Commands

### Environment Setup

```bash
# Authenticate to Dev Hub
sf org login web --alias mydevhub --set-default-dev-hub

# Create scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias myscratch --duration-days 30

# Open scratch org
sf org open --target-org myscratch

# Push source to scratch org
sf project deploy start --target-org myscratch
```

### Package Management

```bash
# Create package (first time only)
sf package create --name "Package Name" --package-type Managed --path force-app --target-dev-hub mydevhub

# Create beta version
sf package version create --package "Package Name" --installation-key YOUR_KEY --wait 20

# Create released version (with code coverage validation)
sf package version create --package "Package Name" --installation-key YOUR_KEY --code-coverage --wait 20

# Promote to released (required for AppExchange)
sf package version promote --package "Package Name@1.0.0-1"

# List package versions
sf package version list --packages "Package Name" --verbose
```

### Security Scanning (REQUIRED Before Every Commit)

```bash
# Install Code Analyzer (if not installed)
sf plugins install @salesforce/sfdx-scanner

# Run AppExchange security rules
sf code-analyzer run --rule-selector AppExchange --target force-app --output-file scan-results.html

# Run Data Flow Analysis for CRUD/FLS violations
sf code-analyzer run --rule-selector sfge --target force-app --output-file dfa-scan.csv

# Run all security categories
sf code-analyzer run --rule-selector "Security,Performance,BestPractices" --target force-app
```

## Code Review Checklist

Before approving any PR, verify:

- [ ] All classes have explicit sharing declaration
- [ ] All SOQL uses `WITH USER_MODE`
- [ ] All DML uses `AccessLevel.USER_MODE`
- [ ] No string concatenation in dynamic SOQL
- [ ] All user input uses bind variables
- [ ] No hardcoded credentials or IDs
- [ ] Error messages are generic (no stack traces)
- [ ] External callouts use HTTPS only
- [ ] Code Analyzer scan passes with no High/Critical violations

## Testing Requirements

- Minimum 75% code coverage (required for package creation)
- Test with users of different permission levels
- Test CRUD/FLS enforcement with limited users
- Test sharing rule enforcement
- Test SOQL injection prevention

```apex
@isTest
static void testUserModeEnforcesFls() {
    // Create limited user
    User limitedUser = createLimitedUser();
    
    System.runAs(limitedUser) {
        try {
            // This should fail or strip inaccessible fields
            List<Account> accounts = [SELECT Id, Name FROM Account WITH USER_MODE];
        } catch (QueryException e) {
            System.assert(e.getMessage().contains('sObject type'), 'Should be CRUD violation');
        }
    }
}
```

## Documenting Security Bypasses

If you MUST bypass CRUD/FLS (rare cases only), document with:

```apex
/* sfge-disable-next-line ApexFlsViolationRule */
// BYPASS JUSTIFICATION: System logging operation - Log__c is internal-only
// and never exposed to users. Records are created by system processes
// for debugging purposes. Reviewed and approved: [date] [reviewer]
List<Log__c> logs = [SELECT Id FROM Log__c];
```

## Pre-Submission Checklist

### Code Security
- [ ] All classes declare sharing explicitly
- [ ] CRUD/FLS enforced on all queries and DML
- [ ] No SOQL/SOSL injection vulnerabilities
- [ ] No hardcoded credentials
- [ ] XSS prevention in Visualforce (if any)
- [ ] External callouts use HTTPS only
- [ ] Code Analyzer scan passes
- [ ] Checkmarx scan completed (via Partner Security Portal)

### LWC Security
- [ ] No inline JavaScript in templates
- [ ] No eval() or Function() constructors
- [ ] External resources via Static Resources
- [ ] CSP Trusted Sites documented

### Documentation
- [ ] Installation guide with permission requirements
- [ ] List all external endpoints and data flows
- [ ] Document any CRUD/FLS bypasses with justification
- [ ] Test credentials for security review environment

### Package Configuration
- [ ] Namespace registered and linked
- [ ] Package version promoted to Released
- [ ] 75%+ code coverage
- [ ] PostInstall/UninstallHandler tested (if any)

## Common Security Review Failures

| Issue | Solution |
|-------|----------|
| CRUD/FLS not enforced | Use `WITH USER_MODE` or `stripInaccessible` |
| SOQL injection | Use bind variables, never string concatenation |
| Missing sharing declaration | Add `with sharing` to all classes |
| Hardcoded credentials | Use Named Credentials or Custom Metadata |
| HTTP (not HTTPS) callouts | Always use HTTPS |
| Sensitive error messages | Use generic messages, log details server-side |
| Inline JavaScript in LWC | Use proper event binding (`onclick={handler}`) |

## Files to Never Commit

- `.sfdx/` - Local SFDX configuration
- `*.log` - Log files
- Credentials or API keys of any kind
- Org-specific IDs

## Contact

For security questions or bypass approvals, contact: [Security Lead]
