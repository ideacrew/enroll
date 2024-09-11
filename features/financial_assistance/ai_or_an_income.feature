Feature: Start a new Financial Assistance Application and fills out Other Income form

  Background: User logs in and visits applicant's other income page and is not an indian or alaska tribe
    Given bs4_consumer_flow feature is disable
    Given a consumer, with a family, exists
    And is logged in
    And the consumer is RIDP verified
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    When the user will navigate to the FAA Household Info page
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page

  Scenario: Non American Indian or Alaska Native tribal sources user with feature enabled
    Given applicant is not a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    Then user should not see a question about income from American Indian or Alaska Native tribal sources

  Scenario: Non American Indian or Alaska Native tribal sources user with feature disabled
    Given applicant is not a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is disabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    Then user should not see a question about income from American Indian or Alaska Native tribal sources

  Scenario: American Indian or Alaska Native tribal sources user with feature disabled
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is disabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    Then user should not see a question about income from American Indian or Alaska Native tribal sources

  Scenario: American Indian or Alaska Native tribal sources user with feature enabled
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    Then user should see a question about income from American Indian or Alaska Native tribal sources

  Scenario: User enters yes to American Indian or Alaska Native tribal income
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    And user entered yes to american indian or alaska native income question
    Then the american indian or alaska native income choices should show

  Scenario: User enters not to American Indian or Alaska Native tribal income
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    And user entered no to american indian or alaska native income question
    Then the american indian or alaska native income choices should not show

  Scenario: User enters american indian or alaska native income adjustments
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    And user entered yes to american indian or alaska native income question
    And the user fills out the required other income information
    Then the save button should be enabled
    And the user saves the other income information
    Then the other income information should be saved on the page

  Scenario: User enters american indian or alaska native income with a start date in the future
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And FAA income_and_deduction_date_warning feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    And user entered yes to american indian or alaska native income question
    And the user enters a start date in the future
    Then the user should see the start date warning message

  Scenario: User american indian or alaska native income with an end date
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And FAA income_and_deduction_date_warning feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    And user entered yes to american indian or alaska native income question
    And the user enters an end date
    Then the user should see the end date warning message

  Scenario: User enters american indian or alaska native income with a start date in the future and an end date
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And FAA income_and_deduction_date_warning feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    And user entered yes to american indian or alaska native income question
    And the user enters a start date in the future
    And the user enters an end date
    Then the user should see the start date and end date warning messages

  Scenario: american indian or alaska native Cancel button functionality
    Given applicant is a member of an American Indian or Alaska Native Tribe
    And american indian or alaska native income feature is enabled
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant
    And user entered yes to american indian or alaska native income question
    When the user cancels the form
    Then the american indian or alaska native income choices should not show
