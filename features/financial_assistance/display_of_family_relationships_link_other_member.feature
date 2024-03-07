Feature: Conditional Display of Family Relationships link in the left nav of the FAA Household Info page.

  Background: Household Info page
    Given a consumer exists
    And is logged in
    And a benchmark plan exists
    And the user is RIDP verified
    And the user will navigate to the FAA Household Info page

  Scenario: Family relationships link displays on Review Your Application page
    Given at least one other household members exist
    And all applicants are in Info Completed state
    And the Family Relationships link displays in the left column of the page
    And the Family Relationships link is enabled
    When the user clicks the Family Relationships link
    Then the user will navigate to the Family relationships page
    When the user clicks CONTINUE
    Then the user is on the Review Your Application page
    And Family Relationships left section WILL display