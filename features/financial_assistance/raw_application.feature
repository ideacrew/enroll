Feature: Cost Savings Raw Application

  Admin will be able to access Cost Savings - Full application action only when
  Financial Assistance feature is enabled. When FAA feature disabled,
  consumer shall not be able see or access Cost Savings page.

  Background:
    Given bs4_consumer_flow feature is disable
    Given the FAA feature configuration is enabled
    And FAA display_medicaid_question feature is enabled
    And a family with financial application and applicants in determined state exists
    And the primary applicant age greater than 18
    And the user is RIDP verified
    And the user with hbx_staff role is logged in

  Scenario: FAA Feature Is Enabled - Admin logs in and clicks on Person
    When admin visits home page
    And the Cost Savings link is visible
    And user clicks on Cost Savings link
    When user clicks on Action dropdown
    Then the user should see text Full Application

  Scenario: FAA Feature Is Enabled - Admin clicks on Full application action
    When admin visits home page
    And the Cost Savings link is visible
    And user clicks on Cost Savings link
    When user clicks on Action dropdown
    And the user should see text Full Application
    When user clicks on Full application action
    Then user should land on full application page and should see 2 view my applications buttons
    Then user should see 2 print buttons
    And user should see Medicaid eligibility question

  Scenario: FAA Feature Is Enabled - Admin clicks on Full application action
    And the user with hbx_staff role is logged in
    When admin visits home page
    And the Cost Savings link is visible
    And admin clicks on Cost Savings link
    When admin clicks on Action dropdown
    And the admin should see text Full Application
    When admin clicks on Full application action
    Then admin should see county under Mailing and Home address

  Scenario: MVS Feature Is Enabled - Admin clicks on Full application action and sees MVS question
    And FAA minimum_value_standard_question feature is enabled
    And FAA disable_employer_address_fields feature is enabled
    And the user with hbx_staff role is logged in
    When admin visits home page
    And the Cost Savings link is visible
    And admin clicks on Cost Savings link
    When admin clicks on Action dropdown
    And the admin should see text Full Application
    Given the consumer has a benefit
    And the consumer has an esi benefit
    When admin clicks on Full application action
    Then the health plan meets mvs and affordable question should show

  Scenario: Admin clicks on Full application action, sees TYPES of other income
    When the ssi_income_types feature is enabled
    When an applicant with other income exists for a determined financial application
    And the primary applicant age greater than 18
    And the user is RIDP verified
    And the user with hbx_staff role is logged in
    When admin visits home page
    And the Cost Savings link is visible
    And admin clicks on Cost Savings link
    When admin clicks on Action dropdown
    And the admin should see text Full Application
    When admin clicks on Full application action
    Then the social security type - retirement benefits should show
    And the wages and salaries type should display

  Scenario: Admin clicks on review application action, sees caretaker questions
    And the user with hbx_staff role is logged in
    When admin visits home page
    And the Cost Savings link is visible
    And admin clicks on Cost Savings link
    When admin clicks on Action dropdown
    And the admin should see text Full Application
    When admin clicks on Full application action
    Then the caretaker questions should show
