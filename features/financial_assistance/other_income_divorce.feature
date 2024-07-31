Feature: Start a new Financial Assistance Application and fills out Other Income form with divorce agreement year feature disabled

  Background: User logs in and visits applicant's other income page
    Given bs4_consumer_flow feature is disable
    Given divorce agreement year feature is disabled
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the consumer is RIDP verified
    And the FAA feature configuration is enabled
    Given FAA income_and_deduction_date_warning feature is enabled
    When the user will navigate to the FAA Household Info page
    Given ssi types feature is enabled
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant

    Scenario: User answers yes to having other income
    Given  divorce agreement year feature is disabled
    Given the user answers yes to having other income
    Then the other income choices should show
    Then the divorce agreement copy should not show