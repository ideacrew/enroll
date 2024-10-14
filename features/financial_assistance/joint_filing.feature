Feature: Joint Filing Taxes

  Background: User can edit tax info page for a household member
    Given bs4_consumer_flow feature is disable
    Given the FAA feature configuration is enabled
    Given a consumer, with a family, exists
    Given that the user is on the FAA Household Info page
  
  Scenario: Filing Jointly is Selected
    Given the user clicks add Income and Coverage Information
    And the user is on the tax info page
    And the user selects they are filing jointly
    And the user lands on the Job Incomes Page
    And the user navigates back to the tax info page
    Then the user will see that the is filing jointly question is true