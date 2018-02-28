Feature: Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the user SSN is nil
    And the user has an eligible immigration status
    And the user has an age between 18 and 19 years old
    And the user will navigate to the FAA Household Info page
    When they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the Health Coverage page via the left nav (also confirm they are on the Health Coverage page)

  Scenario: User answers no to currently having health coverage
    Given the user answers no to currently having health coverage
    Then the health coverage choices should not show

  Scenario: User answers no to currently having access to other health coverage
    Given the user answers no to currently having access to other health coverage
    Then the other health coverage choices should not show

  Scenario: User answers yes to currently having health coverage
    Given the user answers yes to currently having health coverage
    Then the health coverage choices should show

  Scenario: User answers yes to currently having access to other health coverage
    Given the user answers yes to currently having access to other health coverage
    Then the other health coverage choices should show

  Scenario: Health coverage form shows after checking an option (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a health coverage checkbox
    Then the health coverage form should show
