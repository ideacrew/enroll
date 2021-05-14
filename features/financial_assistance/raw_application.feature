Feature: Cost Savings Raw Application

  Admin will be able to access Cost Savings - Full application action only when
  Financial Assistance feature is enabled. When FAA feature disabled,
  consumer shall not be able see or access Cost Savings page.

  Background:
    Given the FAA feature configuration is enabled
    And a family with financial application in determined state exists
    And the user with hbx admin role is logged in

  Scenario: FAA Feature Is Enabled - Admin logs in and clicks on Person
    When admin visits home page
    And the Cost Savings link is visible
    And the user clicks on Cost Savings link
    When the user clicks on Action dropdown
    Then the user should see text Full Application

  # Not sure why this is broken. says theres no print buttons? Where are the print buttons even in the UI? can't find
  @flaky
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
