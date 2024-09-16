Feature: Review your application page functionality 1

  Background: Review your application page
    Given bs4_consumer_flow feature is disable
    Given a consumer exists with family
    And the consumer is RIDP verified
    And is logged in
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page

  Scenario: Submit button is enabled when required checkboxes are checked and name is signed
    Given the user clicks CONTINUE
    Then the user is on the Your Preferences page
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page
    And the user has signed their name
    And all required questions are answered
    And the user should be able to see medicaid determination question
    Then the submit button will be enabled

  Scenario: Submit button is disabled when a checkbox is not checked and name is not signed
    Given the user clicks CONTINUE
    Then the user is on the Your Preferences page
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page
    Then the submit button will be disabled

  Scenario: Submit button is disabled when checkboxes are not checked but name is signed
    Given the user clicks CONTINUE
    Then the user is on the Your Preferences page
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page
    And the user has signed their name
    Then the submit button will be disabled

  Scenario: Parent Living Outside Home Button is Selected
    Given the user has a parent living outside the home
    Given the user clicks CONTINUE
    Then the user is on the Your Preferences page
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page
    Then the Parent Living Outside Home Attestation Checkbox is present

  Scenario: Editing Income Adjustments
    Given the pencil icon displays for each instance of income adjustments
    And the user clicks the pencil icon for INCOME ADJUSTMENTS
    Then the user should navigate to the Income Adjustments page

  Scenario: Net Annual Salary Displays for Applicants
    Given FAA net_annual_income_display feature is enabled
    And the page is refreshed with feature enabled
    Then the user should see the net annual income displayed

  Scenario: Editing Wages & Salaries
    Given the pencil icon displays for each instance of income
    And the user clicks the pencil icon for income
    Then the user should navigate to the Income page

  Scenario: Editing Self Employment Income
    Given the pencil icon displays for each instance of income
    And the user clicks the pencil icon for Income
    Then the user should navigate to the Income page

  Scenario: Editing other income
    Given the pencil icon displays for each instance of income
    And the user clicks the pencil icon for Income
    Then the user should navigate to the Income page

  Scenario: Editing member level tax info
    Given the user views the TAX INFO row
    When the user clicks the applicant's pencil icon for TAX INFO
    Then the user should navigate to the Tax Info page
    And all data should be presented as previously entered

  Scenario: Editing member level income
    Given the user views the Income row
    When the user clicks the applicant's pencil icon for Income
    Then the user should navigate to the Income page
    And all data should be presented as previously entered

  Scenario: Editing member level income adjustments
    Given the user views the INCOME ADJUSTMENTS row
    When the user clicks the applicant's pencil icon for Income Adjustments
    Then the user should navigate to the Income Adjustments page
    And all data should be presented as previously entered

  Scenario: Editing member level health coverage
    Given the user views the HEALTH COVERAGE row
    When the user clicks the applicant's pencil icon for Health Coverage
    Then the user should navigate to the Health Coverage page
    And all data should be presented as previously entered



