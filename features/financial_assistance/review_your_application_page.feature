Feature: Review your application page functionality

  Background: Review your application page
    Given a consumer exists
    And is logged in
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page

  Scenario: Editing Income Adjustments
    Given the pencil icon displays for each instance of income adjustments
    And the user clicks the pencil icon for INCOME ADJUSTMENTS
    Then the user should navigate to the Income Adjustments page

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
