Feature: User can add or delete applicant's mailing address from Applicant Edit page

  Background: Household Info page
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    When that the user is on FAA Household Info: Family Members page

  Scenario: Deletes mailing address for primary applicant
    Given the applicant only has one home address and one mailing address
    And the user clicks edit applicant
    And the user sees Remove Mailing Address button
    And the user clicks Remove Mailing Address button
    And user clicks confirm member button
    And the user clicks edit applicant
    Then user should not see the deleted mailing address
    And the user sees Add Mailing Address button
