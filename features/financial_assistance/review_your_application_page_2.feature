Feature: Review your application page functionality 2

  Background: Review your application page
    Given bs4_consumer_flow feature is disable
    And the consumer is RIDP verified
    And is logged in
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page

  Scenario: Editing member level other questions
    Given the user views the OTHER QUESTIONS row
    When the user clicks the applicant's pencil icon for Other Questions
    Then the user should navigate to the Other Questions page
    And all data should be presented as previously entered

  Scenario: Navigation to Your Prefences page
    Given the user is on the Review Your Application page
    And the CONTINUE button is enabled
    When the user clicks CONTINUE
    Then the user should navigate to the Your Preferences page

  Scenario: The user navigates to the review and submit page with incomplete applicant information
    Given the user is on the Family Information page with missing applicant income amount
    When the user clicks CONTINUE
    Then the user should see a missing applicant info error message
    And the CONTINUE button is functionally DISABLED

  Scenario: The user navigates to the review and submit page with applicant mec evidence
    Given the mec check feature is enabled
    Given the coverage check banners feature is enabled
    Given the user will navigate to the FAA Household Info page
    And an applicant has outstanding local mec evidence
    When the user clicks CONTINUE
    Then they should see the Medicaid Currently Enrolled warning text

  Scenario: The user navigates to the review and submit page with applicant shop coverage
    Given the shop coverage check feature is enabled
    Given the coverage check banners feature is enabled
    Given the user will navigate to the FAA Household Info page
    And an applicant has shop coverage
    When the user clicks CONTINUE
    Then they should see the shop coverage exists warning text

  Scenario: The user navigates to the review and submit page without applicant shop coverage
    Given the shop coverage check feature is enabled
    Given the coverage check banners feature is enabled
    Given the user will navigate to the FAA Household Info page
    When the user clicks CONTINUE
    Then they should not see the shop coverage exists warning text

  Scenario: Admin clicks on Full application action, sees caretaker questions
    Given that a family has a Financial Assistance application in the draft state
    When the primary caretaker question configuration is enabled
    When the primary caretaker relationship question configuration is enabled
    And an applicant has an existing non ssn apply reason
    And the user will navigate to the FAA Household Info page
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page
    Then the caretaker questions should show