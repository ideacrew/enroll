Feature: Tax Info Page with bs4 enabled

  Background: User can edit tax info page for a household member
    Given bs4_consumer_flow feature is enabled
    Given the contrast level aa feature is enabled
    Given the FAA feature configuration is enabled
    Given a consumer, with a family, exists
    Given that the user is on the FAA Household Info page with bs4 enabled
  
  Scenario: Filing Jointly is Selected
    Given the user clicks add Income and Coverage Information
    And the user selects they are filing jointly
    And the user navigates back to the tax info page
    Then the user will see that the is filing jointly question is true