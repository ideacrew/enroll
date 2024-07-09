# frozen_string_literal: true

Feature: Start a new Financial Assistance Application and fills out the job and self employed income forms

  Background: User logs in and visits applicant's Job income page
    Given bs4_consumer_flow feature is disable
    Given EnrollRegistry crm_update_family_save feature is disabled
    Given EnrollRegistry crm_publish_primary_subscriber feature is disabled
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the consumer is RIDP verified
    And the FAA feature configuration is enabled
    Given FAA income_and_deduction_date_warning feature is enabled
    When the user will navigate to the FAA Household Info page
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the applicant's Job income page

  Scenario: Unemployment Cancel button functionality
    Given the user answers yes to having and income from an employer
    When the user cancels the form
    And the job income form should not show
    And NO should be selected again for job income


  Scenario: User answers no to having job income
    Given the user answers no to having an income from an employer
    Then the job income form should not show

  Scenario: User answers no to having self employment income
    Given the user answers no to having self employment income
    Then self employment form should not show

  Scenario: User answers yes to having job income
    Given the user answers yes to having and income from an employer
    Then the job income form should show

  Scenario: "Continue" button should be enabled after selecting "No" on both income questions
    Given the user answers no to having an income from an employer
    Then the job income form should not show
    Given the user answers no to having self employment income
    Then self employment form should not show
    Then the CONTINUE button will be ENABLED
    When the user clicks CONTINUE
    Then the user will be on the Other Income page
    And there will be a checkmark next to the completed Job Income page link

  Scenario: User answers yes to having self employment income
    Given the user answers yes to having self employment income
    Then self employment form should show

  Scenario: User enters employer information
    Given the user answers yes to having and income from an employer
    And the user fills out the required employer information
    Then the save button should be enabled
    And the user saves the employer information
    Then the employer information should be saved on the page

  Scenario: User enters employer information with end date less than start date
    Given the user answers yes to having and income from an employer
    And the user fills out the required employer information with incorrect dates
    Then the save button should be enabled
    And the user saves the employer information
    Then the user should see a JS alert

  Scenario: User enters employer information with a start date in the future
    Given the user answers yes to having and income from an employer
    And the user enters a start date in the future
    Then the user should see the start date warning message

  Scenario: User enters employer information with an end date
    Given the user answers yes to having and income from an employer
    And the user enters an end date
    Then the user should see the end date warning message

  Scenario: User enters employer information with a start date in the future and an end date
    Given the user answers yes to having and income from an employer
    And the user enters a start date in the future
    And the user enters an end date
    Then the user should see the start date and end date warning messages

  Scenario: User enters employer information when there is more than one employer
    Given the user has entered at least one job income information
    When the Add Another Job Income link appears
    And the user adds another income
    And the job income form should show
    And the user fills out the required employer information
    And the save button should be enabled
    And the user saves the employer information
    Then the new employer information should be saved on the page

  Scenario: User enters self employment information
    Given the user answers yes to having self employment income
    And the user fills out the required self employment information
    Then the save button should be enabled
    And the user saves the self employment information
    Then the self employment information should be saved on the page

  Scenario: User enters self employment information with end date less than start date
    Given the user answers yes to having self employment income
    And the user fills out the required self employment information with incorrect dates
    Then the save button should be enabled
    And the user saves the self employment information

  Scenario: User enters self employment information with a start date in the future
    Given the user answers yes to having self employment income
    And the user enters a start date in the future
    Then the user should see the start date warning message

  Scenario: User enters self employment information with an end date
    Given the user answers yes to having self employment income
    And the user enters an end date
    Then the user should see the end date warning message

  Scenario: User enters self employment information with a start date in the future and an end date
    Given the user answers yes to having self employment income
    And the user enters a start date in the future
    And the user enters an end date
    Then the user should see the start date and end date warning messages

  Scenario: User enters self employment information when there is more than one self employment income
    Given the user has entered at least one self employment information
    When the Add Another Self Employment link appears
    And the user adds another self employment income
    And self employment form should show
    And the user fills out the required self employment information
    And the save button should be enabled
    And the user saves the self employment information
    Then the self employment information should be saved on the page

  Scenario: Confirmation pop-up functionality
    When the user clicks the BACK TO ALL HOUSEHOLD MEMBERS link
    Then a modal should show asking the user are you sure you want to leave this page

  Scenario: "Not sure?" popups open as expected
    Given the user is on the Job Income page
    When the user clicks the Not sure link next to the employer income question
    Then the user should see the popup for the employer income question
    And the user closes the open income question modal
    When the user clicks the Not sure link next to the self employment income question
    Then the user should see the popup for the self employment income question
