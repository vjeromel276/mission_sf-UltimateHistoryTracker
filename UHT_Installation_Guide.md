# Ultimate History Tracker (UHT) - Installation Guide

**Version:** 1.0  
**Package Namespace:** `missionsf`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Step 1: Install the Package](#step-1-install-the-package)
4. [Step 2: Enable Change Data Capture (CDC)](#step-2-enable-change-data-capture-cdc)
5. [Step 3: Create a Connected App](#step-3-create-a-connected-app)
6. [Step 4: Create an Auth Provider](#step-4-create-an-auth-provider)
7. [Step 5: Create a Named Credential](#step-5-create-a-named-credential)
8. [Step 6: Configure Field Tracking](#step-6-configure-field-tracking)
9. [Step 7: Verify Installation](#step-7-verify-installation)
10. [Troubleshooting](#troubleshooting)
11. [Appendix: Permission Set Assignment](#appendix-permission-set-assignment)

---

## 1. Overview

Ultimate History Tracker (UHT) provides comprehensive field change tracking for any Salesforce object. Unlike standard Field History Tracking (limited to 20 fields per object), UHT can track unlimited fields and captures changes made via:

- User interface (Lightning, Classic)
- API integrations
- Flows and Process Builder
- Data Loader and import tools
- Apex code

**How it works:** UHT uses Salesforce's Change Data Capture (CDC) feature to detect field changes in real-time and stores them in a custom Change Log object for reporting and auditing.

**Estimated Setup Time:** 15-20 minutes

---

## 2. Prerequisites

Before you begin, ensure you have:

- [ ] **System Administrator** profile or equivalent permissions
- [ ] Access to **Setup** in your Salesforce org
- [ ] Knowledge of which objects and fields you want to track

**Important:** UHT requires a one-time configuration of OAuth credentials to enable automatic trigger deployment. This guide walks you through each step.

---

## Step 1: Install the Package

### 1.1 Install from AppExchange

1. Navigate to the **Ultimate History Tracker** listing on AppExchange
2. Click **Get It Now**
3. Select the org where you want to install (Production or Sandbox)
4. Choose **Install for Admins Only** (recommended for initial setup)
5. Click **Install**
6. Wait for the installation email confirmation (typically 1-5 minutes)

### 1.2 Verify Installation

1. Go to **Setup** → Quick Find: **Installed Packages**
2. Confirm **Ultimate History Tracker** appears in the list
3. Note the package namespace: `missionsf`

---

## Step 2: Enable Change Data Capture (CDC)

UHT requires Change Data Capture to be enabled for each object you want to track. This is a standard Salesforce feature available in all editions.

### 2.1 Navigate to CDC Settings

1. Go to **Setup**
2. In Quick Find, search for **Change Data Capture**
3. Click **Change Data Capture** under Integrations

### 2.2 Select Objects to Track

1. In the **Available Entities** column on the left, find the objects you want to track (e.g., Account, Contact, Opportunity)
2. Select each object and click the **Right Arrow (>)** to move it to **Selected Entities**
3. Click **Save**

**Example - Enabling CDC for common objects:**
```
Selected Entities:
├── Account
├── Contact
├── Lead
├── Opportunity
└── Case
```

> **Note:** You can return to this page anytime to add or remove objects from CDC tracking.

---

## Step 3: Create a Connected App

UHT needs OAuth credentials to deploy tracking triggers automatically. This requires creating a Connected App.

### 3.1 Navigate to App Manager

1. Go to **Setup**
2. In Quick Find, search for **App Manager**
3. Click **App Manager**

### 3.2 Create New Connected App

1. Click **New Connected App** (top right)

   > **Note:** If you see a message about Connected Apps being restricted, click the **New Connected App** button in the "Connected Apps" section at the bottom of the page.

2. Fill in the **Basic Information**:

   | Field | Value |
   |-------|-------|
   | Connected App Name | `UHT API Access` |
   | API Name | `UHT_API_Access` (auto-fills) |
   | Contact Email | Your email address |

3. In the **API (Enable OAuth Settings)** section:
   - Check **Enable OAuth Settings**
   
4. Additional fields appear. Fill in:

   | Field | Value |
   |-------|-------|
   | Callback URL | `https://login.salesforce.com/services/oauth2/callback` |
   | Selected OAuth Scopes | Add these two scopes: |
   | | • **Full access (full)** |
   | | • **Perform requests at any time (refresh_token, offline_access)** |

5. Leave all other settings as default
6. Click **Save**
7. Click **Continue** on the confirmation dialog

### 3.3 Get Consumer Credentials

After saving, you need to retrieve the Consumer Key and Secret:

1. On the Connected App detail page, find **API (Enable OAuth Settings)**
2. Click **Manage Consumer Details**
3. You may be prompted to verify your identity (check email for verification code)
4. **Copy and save** both values:
   - **Consumer Key** (long alphanumeric string)
   - **Consumer Secret** (shorter alphanumeric string)

> **Important:** Keep these credentials secure. You'll need them in the next step.

---

## Step 4: Create an Auth Provider

The Auth Provider connects your Connected App to Salesforce's authentication system.

### 4.1 Navigate to Auth Providers

1. Go to **Setup**
2. In Quick Find, search for **Auth. Providers**
3. Click **Auth. Providers**

### 4.2 Create New Auth Provider

1. Click **New**
2. Select **Provider Type:** `Salesforce`
3. Fill in the form:

   | Field | Value |
   |-------|-------|
   | Name | `UHT_Salesforce_Auth` |
   | URL Suffix | `UHT_Salesforce_Auth` (auto-fills) |
   | Consumer Key | Paste the Consumer Key from Step 3.3 |
   | Consumer Secret | Paste the Consumer Secret from Step 3.3 |
   | Authorize Endpoint URL | Leave default |
   | Token Endpoint URL | Leave default |
   | Default Scopes | `full refresh_token` |

4. Click **Save**

### 4.3 Copy the Callback URL

After saving, scroll down to the **Salesforce Configuration** section and find:

**Callback URL:** `https://[your-domain].my.salesforce.com/services/authcallback/UHT_Salesforce_Auth`

**Copy this entire URL** - you'll need it in the next section.

### 4.4 Update Connected App Callback URL

1. Go back to **Setup** → **App Manager**
2. Find **UHT API Access** in the list
3. Click the dropdown arrow (▼) on the right → **Edit**
4. In **Callback URL**, replace the existing URL with the Callback URL you copied in Step 4.3
5. Click **Save**

> **Important:** Wait 2-3 minutes for the changes to propagate before proceeding.

---

## Step 5: Create a Named Credential

The Named Credential allows UHT to make secure API calls using OAuth authentication.

### 5.1 Navigate to Named Credentials

1. Go to **Setup**
2. In Quick Find, search for **Named Credentials**
3. Click **Named Credentials**

### 5.2 Create New Named Credential

1. Click **New** (or **New Legacy** if shown)

   > **Note:** If you see options for "New" vs "New Legacy", choose **New Legacy**.

2. Fill in the form:

   | Field | Value |
   |-------|-------|
   | Label | `UHT Self Callout` |
   | Name | `UHT_Self_Callout` |
   | URL | Your org's My Domain URL (e.g., `https://yourcompany.my.salesforce.com`) |
   | Identity Type | `Named Principal` |
   | Authentication Protocol | `OAuth 2.0` |
   | Authentication Provider | Select `UHT_Salesforce_Auth` |
   | Scope | `full refresh_token` |
   | Start Authentication Flow on Save | **Check this box** |

3. Click **Save**

### 5.3 Authenticate

After clicking Save:

1. A Salesforce login page opens in a new window/tab
2. Log in with your **Administrator credentials**
3. Click **Allow** when prompted to authorize access
4. The window closes and returns you to the Named Credential page

### 5.4 Verify Authentication

On the Named Credential detail page, confirm:

- **Authentication Status:** `Authenticated as [your-username]`

If you see "Authentication Status: Pending" or an error, see [Troubleshooting](#troubleshooting).

---

## Step 6: Configure Field Tracking

Now you're ready to select which fields to track using the UHT Admin Console.

### 6.1 Open the Admin Console

1. Click the **App Launcher** (9-dot grid icon)
2. Search for **Ultimate History Tracker**
3. Click on the **UHT Admin Console** tab

### 6.2 Understanding the Interface

The Admin Console displays all CDC-capable objects with status indicators:

| Indicator | Meaning |
|-----------|---------|
| ✓ CDC (green) | CDC is enabled for this object in Setup |
| ✗ CDC (red) | CDC is not enabled - go to Setup to enable it |
| **Custom** badge | This is a custom object |
| **Tracked** badge | This object already has UHT tracking configured |

### 6.3 Select Objects and Fields

1. **Check the checkbox** next to each object you want to track
   
   > Objects must show green "✓ CDC" status. If an object shows red, go back to [Step 2](#step-2-enable-change-data-capture-cdc) to enable CDC.

2. **Click on an object row** to expand it and see available fields

3. **Select individual fields** to track, or click **Toggle All Fields** to select/deselect all

4. Repeat for each object you want to track

### 6.4 Save Configuration

1. Review your selections using the counter: "X of Y objects selected"
2. Click **Save**
3. Wait for the deployment to complete (usually 30-60 seconds)
4. A success message confirms the configuration is saved

**What happens when you save:**
- UHT creates tracking configuration metadata
- UHT automatically deploys CDC triggers for each selected object
- The triggers begin capturing field changes immediately

---

## Step 7: Verify Installation

Let's confirm everything is working correctly.

### 7.1 Test Field Change Tracking

1. Navigate to a record for an object you configured (e.g., an Account)
2. Edit a field you selected for tracking (e.g., change the Phone number)
3. Save the record

### 7.2 View the Change Log

1. Click the **App Launcher**
2. Search for and open **UHT Change Logs** (or navigate to the tab)
3. Look for a recent record showing:
   - **Object Name:** The object you edited (e.g., Account)
   - **Field Name:** The field you changed (e.g., Phone)
   - **Old Value:** The previous value
   - **New Value:** The new value
   - **Changed By:** Your username
   - **Changed At:** The timestamp

### 7.3 Verify Trigger Deployment

1. Go to **Setup** → Quick Find: **Apex Triggers**
2. Confirm you see triggers named like:
   - `AccountChangeEventTrigger`
   - `ContactChangeEventTrigger`
   - (One for each object you configured)

---

## Troubleshooting

### Named Credential Shows "Pending" or Authentication Failed

**Cause:** The Callback URL in the Connected App doesn't match the Auth Provider.

**Solution:**
1. Go to **Setup** → **Auth. Providers** → **UHT_Salesforce_Auth**
2. Copy the **Callback URL** from the Salesforce Configuration section
3. Go to **Setup** → **App Manager** → **UHT API Access** → **Edit**
4. Paste the Callback URL into the Callback URL field
5. Save and wait 2-3 minutes
6. Delete and recreate the Named Credential

### "redirect_uri_mismatch" Error

**Cause:** Same as above - URL mismatch.

**Solution:** Follow the steps above to update the Connected App Callback URL.

### CDC Not Capturing Changes

**Possible causes:**
1. CDC not enabled for the object
2. Trigger not deployed
3. Field not selected for tracking

**Solution:**
1. Verify CDC is enabled: **Setup** → **Change Data Capture** → Check object is in "Selected Entities"
2. Verify trigger exists: **Setup** → **Apex Triggers** → Look for `[Object]ChangeEventTrigger`
3. Verify field is tracked: Open UHT Admin Console and confirm the field checkbox is selected

### "Callout loop not allowed" Error

**Cause:** This is expected behavior - UHT handles this internally.

**Solution:** No action needed. The trigger deployment still succeeds.

### Objects Show Red "CDC" Status

**Cause:** Change Data Capture is not enabled for that object.

**Solution:** Go to **Setup** → **Change Data Capture** and add the object to Selected Entities.

### Trigger Deployment Failed

**Cause:** Usually means CDC is not enabled for the object.

**Solution:**
1. Enable CDC for the object (Step 2)
2. Return to UHT Admin Console
3. Uncheck and re-check the object
4. Save again

---

## Appendix: Permission Set Assignment

If users other than System Administrators need access to UHT:

### Assign the UHT Permission Set

1. Go to **Setup** → Quick Find: **Permission Sets**
2. Click **UHT Admin** (or **UHT User** for read-only access)
3. Click **Manage Assignments**
4. Click **Add Assignments**
5. Select the users who need access
6. Click **Assign**

### Permission Set Details

| Permission Set | Access Level |
|----------------|--------------|
| UHT Admin | Full access: configure tracking, view logs, manage settings |
| UHT User | Read-only: view change logs only |

---

## Quick Reference: Setup Checklist

Use this checklist to verify all steps are complete:

- [ ] Package installed from AppExchange
- [ ] CDC enabled for desired objects (Setup → Change Data Capture)
- [ ] Connected App created (UHT API Access)
- [ ] Consumer Key and Secret retrieved
- [ ] Auth Provider created (UHT_Salesforce_Auth)
- [ ] Connected App Callback URL updated to match Auth Provider
- [ ] Named Credential created (UHT_Self_Callout)
- [ ] Named Credential shows "Authenticated as [user]"
- [ ] Objects and fields selected in UHT Admin Console
- [ ] Configuration saved successfully
- [ ] Test record edited and change appears in UHT Change Logs

---

## Support

For questions or issues:
- Email: [support email]
- Documentation: [documentation URL]
- AppExchange Listing: [listing URL]

---

*© 2024 MissionSF. All rights reserved.*
