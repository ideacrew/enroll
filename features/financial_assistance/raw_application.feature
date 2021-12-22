Feature: Cost Savings Raw Application

  Admin will be able to access Cost Savings - Full application action only when
  Financial Assistance feature is enabled. When FAA feature disabled,
  consumer shall not be able see or access Cost Savings page.

  Background:
    Given the FAA feature configuration is enabled
    And FAA display_medicaid_question feature is enabled
    And a family with financial application in determined state exists
    And the user with hbx_staff role is logged in

  Scenario: FAA Feature Is Enabled - Admin logs in and clicks on Person
    When admin visits home page
    And the Cost Savings link is visible
    And the user clicks on Cost Savings link
    When the user clicks on Action dropdown
    Then the user should see text Full Application

  Scenario: FAA Feature Is Enabled - Admin clicks on Full application action
    When admin visits home page
    And the Cost Savings link is visible
    And the user clicks on Cost Savings link
    When the user clicks on Action dropdown
    And the user should see text Full Application
    When user clicks on Full application action
    Then user should land on full application page and should see 2 view my applications buttons
    Then user should see 2 print buttons
    And user should see Medicaid eligibility question
    And user should see Claimed as Dependent question
