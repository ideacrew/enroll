Feature: Conditional Display of Family Relationships link in the left nav of the FAA Household Info page.

  Background: Household Info page
    Given a consumer exists
    And is logged in
    And a benchmark plan exists
    And the user is RIDP verified
    And the user will navigate to the FAA Household Info page

  Scenario: Relationships link does not display when there is only one household member
    Given the primary member exists
    Then Family Relationships left section will NOT display
    When all applicants are in Info Completed state
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page
    And Family Relationships left section will NOT display

  Scenario: Relationships link DOES display when there is more than one household member
    Given the primary member exists
    And at least one other household members exist
    Then Family Relationships left section WILL display

  Scenario: Relationships link is disabled when at least on applicant is in progress
    Given at least one other household members exist
    And at least one applicant is in the Info Needed state
    And the Family Relationships link displays in the left column of the page
    Then the Family Relationships link is disabled



