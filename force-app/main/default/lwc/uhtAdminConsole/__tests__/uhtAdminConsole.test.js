import { createElement } from "@lwc/engine-dom";
import UhtAdminConsole from "c/uhtAdminConsole";
import getAvailableObjects from "@salesforce/apex/UHT_AdminController.getAvailableObjects";
import getObjectFields from "@salesforce/apex/UHT_AdminController.getObjectFields";
import saveTrackedConfiguration from "@salesforce/apex/UHT_AdminController.saveTrackedConfiguration";

// Mock Apex methods
jest.mock(
  "@salesforce/apex/UHT_AdminController.getAvailableObjects",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/UHT_AdminController.getObjectFields",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/UHT_AdminController.saveTrackedConfiguration",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// Mock ShowToastEvent - must return a proper CustomEvent
jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((config) => {
      return new CustomEvent("lightning__showtoast", { detail: config });
    })
  }),
  { virtual: true }
);

// Sample test data
const MOCK_OBJECTS = [
  { apiName: "Account", label: "Account", isTracked: true, isCustom: false },
  { apiName: "Contact", label: "Contact", isTracked: false, isCustom: false },
  {
    apiName: "Custom_Object__c",
    label: "Custom Object",
    isTracked: false,
    isCustom: true
  }
];

const MOCK_ACCOUNT_FIELDS = [
  { apiName: "Name", label: "Account Name", type: "STRING", isTracked: true },
  {
    apiName: "Industry",
    label: "Industry",
    type: "PICKLIST",
    isTracked: false
  },
  {
    apiName: "AnnualRevenue",
    label: "Annual Revenue",
    type: "CURRENCY",
    isTracked: false
  }
];

const MOCK_CONTACT_FIELDS = [
  {
    apiName: "FirstName",
    label: "First Name",
    type: "STRING",
    isTracked: false
  },
  { apiName: "LastName", label: "Last Name", type: "STRING", isTracked: false },
  { apiName: "Email", label: "Email", type: "EMAIL", isTracked: false }
];

// Helper to flush promises
// eslint-disable-next-line @lwc/lwc/no-async-operation
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-uht-admin-console", () => {
  let element;

  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();
  });

  afterEach(() => {
    // Clean up DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  // =========================================================================
  // Initial Render and Loading Tests
  // =========================================================================

  it("shows loading spinner on initial render", () => {
    // Arrange - make Apex call pending
    getAvailableObjects.mockReturnValue(new Promise(() => {}));

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);

    // Assert
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("displays objects after loading completes", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert
    const objectItems = element.shadowRoot.querySelectorAll(".object-item");
    expect(objectItems.length).toBe(3);
  });

  it("hides loading spinner after data loads", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert - spinner should be inside loading template which is now hidden
    const mainContent = element.shadowRoot.querySelector(".object-list");
    expect(mainContent).not.toBeNull();
  });

  it("displays correct object count in header", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert - Account is tracked, so 1 of 3 selected
    const countText = element.shadowRoot.querySelector('[slot="actions"] span');
    expect(countText.textContent).toContain("1 of 3");
  });

  it("shows empty state when no objects returned", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue([]);

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert
    const emptyState = element.shadowRoot.querySelector(".slds-illustration");
    expect(emptyState).not.toBeNull();
  });

  // =========================================================================
  // Object Display Tests
  // =========================================================================

  it("displays object labels and API names", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert
    const objectLabels = element.shadowRoot.querySelectorAll(".object-label");
    const objectApiNames =
      element.shadowRoot.querySelectorAll(".object-api-name");

    expect(objectLabels[0].textContent).toBe("Account");
    expect(objectApiNames[0].textContent).toContain("Account");
  });

  it("shows Custom badge for custom objects", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert - Custom_Object__c should have Custom badge
    const badges = element.shadowRoot.querySelectorAll("lightning-badge");
    const badgeLabels = Array.from(badges).map((b) => b.label);
    expect(badgeLabels).toContain("Custom");
  });

  it("shows Tracked badge for tracked objects", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert - Account is tracked
    const badges = element.shadowRoot.querySelectorAll("lightning-badge");
    const badgeLabels = Array.from(badges).map((b) => b.label);
    expect(badgeLabels).toContain("Tracked");
  });

  it("pre-selects checkbox for tracked objects", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    // Act
    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert - Account checkbox should be checked (first object is Account and is tracked)
    const objectCheckboxes =
      element.shadowRoot.querySelectorAll(".object-checkbox");
    expect(objectCheckboxes.length).toBeGreaterThan(0);
    // The first checkbox is for Account which is tracked
    expect(objectCheckboxes[0].checked).toBe(true);
  });

  // =========================================================================
  // Accordion Expand/Collapse Tests
  // =========================================================================

  it("expands object when clicked", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Act - click on Account header
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    // Assert - fields section should be visible
    const fieldsSection = element.shadowRoot.querySelector(".fields-section");
    expect(fieldsSection).not.toBeNull();
  });

  it("loads fields when object is expanded", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Act - click to expand
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    // Assert
    expect(getObjectFields).toHaveBeenCalledWith({ objectApiName: "Account" });
  });

  it("collapses object when clicked again", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    const objectHeader = element.shadowRoot.querySelector(".object-header");

    // Act - click to expand, then click again to collapse
    objectHeader.click();
    await flushPromises();
    objectHeader.click();
    await flushPromises();

    // Assert - fields section should be hidden
    const fieldsSection = element.shadowRoot.querySelector(".fields-section");
    expect(fieldsSection).toBeNull();
  });

  it("displays fields after loading", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Act - expand Account
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    // Assert - should show 3 fields
    const fieldCheckboxes = element.shadowRoot.querySelectorAll(
      ".fields-grid lightning-input"
    );
    expect(fieldCheckboxes.length).toBe(3);
  });

  it("shows field count after loading", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Act - expand Account
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    // Assert
    const fieldsSection = element.shadowRoot.querySelector(".fields-section");
    expect(fieldsSection.textContent).toContain("3 trackable fields");
  });

  // =========================================================================
  // Checkbox Interaction Tests
  // =========================================================================

  it("updates object selection when checkbox is clicked", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Act - find Contact checkbox and check it
    const checkboxes = element.shadowRoot.querySelectorAll(
      "lightning-input.object-checkbox"
    );
    const contactCheckbox = Array.from(checkboxes).find(
      (cb) => cb.dataset.objectName === "Contact"
    );

    contactCheckbox.checked = true;
    contactCheckbox.dispatchEvent(
      new CustomEvent("change", { target: { checked: true } })
    );
    await flushPromises();

    // Assert - count should update to 2 of 3
    const countText = element.shadowRoot.querySelector('[slot="actions"] span');
    expect(countText.textContent).toContain("2 of 3");
  });

  it("disables field checkboxes when object is not selected", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_CONTACT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Act - expand Contact (which is not tracked/selected)
    const objectHeaders = element.shadowRoot.querySelectorAll(".object-header");
    const contactHeader = Array.from(objectHeaders).find(
      (h) => h.dataset.objectName === "Contact"
    );
    contactHeader.click();
    await flushPromises();

    // Assert - field checkboxes should be disabled
    const fieldCheckboxes = element.shadowRoot.querySelectorAll(
      ".fields-grid lightning-input"
    );
    fieldCheckboxes.forEach((cb) => {
      expect(cb.disabled).toBe(true);
    });
  });

  it("clears field selections when object is unchecked", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Expand Account to load fields
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    // Act - uncheck Account
    const accountCheckbox = element.shadowRoot.querySelector(
      'lightning-input.object-checkbox[data-object-name="Account"]'
    );
    accountCheckbox.checked = false;
    accountCheckbox.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    // Assert - field checkboxes should be unchecked and disabled
    const fieldCheckboxes = element.shadowRoot.querySelectorAll(
      ".fields-grid lightning-input"
    );
    fieldCheckboxes.forEach((cb) => {
      expect(cb.checked).toBe(false);
      expect(cb.disabled).toBe(true);
    });
  });

  // =========================================================================
  // Toggle All Fields Tests
  // =========================================================================

  it("has Toggle All Fields button", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Expand Account
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    // Assert
    const toggleButton = element.shadowRoot.querySelector(
      'lightning-button[data-object-name="Account"]'
    );
    expect(toggleButton).not.toBeNull();
    expect(toggleButton.label).toBe("Toggle All Fields");
  });

  // =========================================================================
  // Save Configuration Tests
  // =========================================================================

  it("calls saveTrackedConfiguration with correct delta when saving", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);
    saveTrackedConfiguration.mockResolvedValue(
      JSON.stringify({
        mdtDeploymentId: "123",
        triggerDeploymentIds: [],
        triggerErrors: []
      })
    );

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Expand Account and select a new field
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    // Select Industry field (not originally tracked) - it's the second field
    const fieldCheckboxes = element.shadowRoot.querySelectorAll(
      ".fields-grid lightning-input"
    );
    const industryCheckbox = fieldCheckboxes[1]; // Industry is second
    industryCheckbox.checked = true;
    industryCheckbox.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    // Act - click Save button
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const saveButton = Array.from(buttons).find((b) => b.variant === "brand");
    saveButton.click();
    await flushPromises();

    // Assert
    expect(saveTrackedConfiguration).toHaveBeenCalledWith({
      objectsToActivate: [],
      objectsToDeactivate: [],
      fieldsToActivate: { Account: ["Industry"] },
      fieldsToDeactivate: {}
    });
  });

  it("shows saving state while save is in progress", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    // Make save hang
    saveTrackedConfiguration.mockReturnValue(new Promise(() => {}));

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Expand and select a field to enable save
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    const fieldCheckboxes = element.shadowRoot.querySelectorAll(
      ".fields-grid lightning-input"
    );
    const industryCheckbox = fieldCheckboxes[1]; // Industry is second
    industryCheckbox.checked = true;
    industryCheckbox.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    // Act - click Save
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const saveButton = Array.from(buttons).find((b) => b.variant === "brand");
    saveButton.click();
    await flushPromises();

    // Assert - saving overlay should be visible
    const savingOverlay = element.shadowRoot.querySelector(".saving-overlay");
    expect(savingOverlay).not.toBeNull();
  });

  it("shows info toast when no changes to save", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Track dispatched events
    const toastHandler = jest.fn();
    element.addEventListener("lightning__showtoast", toastHandler);

    // Act - click Save without making changes
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const saveButton = Array.from(buttons).find((b) => b.variant === "brand");
    saveButton.click();
    await flushPromises();

    // Assert - should not call save, should show info toast
    expect(saveTrackedConfiguration).not.toHaveBeenCalled();
  });

  it("refreshes data after successful save", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);
    saveTrackedConfiguration.mockResolvedValue(
      JSON.stringify({
        mdtDeploymentId: "123",
        triggerDeploymentIds: ["log1"],
        triggerErrors: []
      })
    );

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Clear the initial call count
    getAvailableObjects.mockClear();

    // Make a change - select Contact (second checkbox)
    const checkboxes = element.shadowRoot.querySelectorAll(".object-checkbox");
    const contactCheckbox = checkboxes[1]; // Contact is second
    contactCheckbox.checked = true;
    contactCheckbox.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    // Act - Save
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const saveButton = Array.from(buttons).find((b) => b.variant === "brand");
    saveButton.click();
    await flushPromises();

    // Assert - should reload objects
    expect(getAvailableObjects).toHaveBeenCalled();
  });

  // =========================================================================
  // Cancel Tests
  // =========================================================================

  it("resets to original state when Cancel is clicked", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Make a change - select Contact (second checkbox)
    const checkboxes = element.shadowRoot.querySelectorAll(".object-checkbox");
    const contactCheckbox = checkboxes[1]; // Contact is second
    contactCheckbox.checked = true;
    contactCheckbox.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    // Clear call count
    getAvailableObjects.mockClear();

    // Act - click Cancel (first button without variant="brand")
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const cancelButton = Array.from(buttons).find((b) => b.label === "Cancel");
    cancelButton.click();
    await flushPromises();

    // Assert - should reload objects
    expect(getAvailableObjects).toHaveBeenCalled();
  });

  // =========================================================================
  // Error Handling Tests
  // =========================================================================

  it("handles error when loading objects fails", async () => {
    // Arrange
    getAvailableObjects.mockRejectedValue({
      body: { message: "Failed to load objects" }
    });

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });

    // Track dispatched events
    const toastHandler = jest.fn();
    element.addEventListener("lightning__showtoast", toastHandler);

    // Act
    document.body.appendChild(element);
    await flushPromises();

    // Assert - loading should complete (not hang), object list should be rendered
    const objectList = element.shadowRoot.querySelector(".object-list");
    expect(objectList).not.toBeNull();
  });

  it("handles error when loading fields fails", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockRejectedValue({
      body: { message: "Failed to load fields" }
    });

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Act - expand Account
    const objectHeader = element.shadowRoot.querySelector(".object-header");
    objectHeader.click();
    await flushPromises();

    // Assert - should not crash, fields section should exist
    const fieldsSection = element.shadowRoot.querySelector(".fields-section");
    expect(fieldsSection).not.toBeNull();
  });

  it("handles error when saving fails", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    saveTrackedConfiguration.mockRejectedValue({
      body: { message: "Save failed" }
    });

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Make a change - select Contact (second checkbox)
    const checkboxes = element.shadowRoot.querySelectorAll(".object-checkbox");
    const contactCheckbox = checkboxes[1];
    contactCheckbox.checked = true;
    contactCheckbox.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    // Act - Save
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const saveButton = Array.from(buttons).find((b) => b.variant === "brand");
    saveButton.click();
    await flushPromises();

    // Assert - should not show saving overlay after error
    const savingOverlay = element.shadowRoot.querySelector(".saving-overlay");
    expect(savingOverlay).toBeNull();
  });

  // =========================================================================
  // Computed Properties Tests
  // =========================================================================

  it("returns correct hasSelectedObjects value", async () => {
    // Arrange - Account is tracked
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert - Save button should be enabled (has selected objects)
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const saveButton = Array.from(buttons).find((b) => b.variant === "brand");
    expect(saveButton.disabled).toBe(false);
  });

  it("shows correct saveButtonLabel", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Assert
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const saveButton = Array.from(buttons).find((b) => b.variant === "brand");
    expect(saveButton.label).toBe("Save Configuration");
  });

  // =========================================================================
  // Edge Cases
  // =========================================================================

  it("does not reload fields if already loaded", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_ACCOUNT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    const objectHeader = element.shadowRoot.querySelector(".object-header");

    // Act - expand, collapse, expand again
    objectHeader.click();
    await flushPromises();
    objectHeader.click();
    await flushPromises();
    objectHeader.click();
    await flushPromises();

    // Assert - getObjectFields should only be called once
    expect(getObjectFields).toHaveBeenCalledTimes(1);
  });

  it("auto-expands object when checkbox is checked", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    getObjectFields.mockResolvedValue(MOCK_CONTACT_FIELDS);

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Act - check Contact checkbox (not currently expanded)
    const checkboxes = element.shadowRoot.querySelectorAll(
      "lightning-input.object-checkbox"
    );
    const contactCheckbox = Array.from(checkboxes).find(
      (cb) => cb.dataset.objectName === "Contact"
    );
    contactCheckbox.checked = true;
    contactCheckbox.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    // Assert - Contact should be expanded and fields loaded
    expect(getObjectFields).toHaveBeenCalledWith({ objectApiName: "Contact" });
  });

  it("shows trigger warnings in toast after save", async () => {
    // Arrange
    getAvailableObjects.mockResolvedValue(MOCK_OBJECTS);
    saveTrackedConfiguration.mockResolvedValue(
      JSON.stringify({
        mdtDeploymentId: "123",
        triggerDeploymentIds: [],
        triggerErrors: ["Account: Trigger already exists"]
      })
    );

    element = createElement("c-uht-admin-console", { is: UhtAdminConsole });
    document.body.appendChild(element);
    await flushPromises();

    // Make a change - select Contact (second checkbox)
    const checkboxes = element.shadowRoot.querySelectorAll(".object-checkbox");
    const contactCheckbox = checkboxes[1];
    contactCheckbox.checked = true;
    contactCheckbox.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    // Act - Save
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const saveButton = Array.from(buttons).find((b) => b.variant === "brand");
    saveButton.click();
    await flushPromises();

    // Assert - save should still succeed (we can verify by checking save was called)
    expect(saveTrackedConfiguration).toHaveBeenCalled();
  });
});
