Feature: Functionality for the Destroy Applicant

  Background: Household info page
    Given a consumer exists
    And is logged in
    And a benchmark plan exists
    And the user is RIDP verified
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And at least two other household members exist

  Scenario: destroy applicant link exists
    Given the primary member exists
    Then the user should click on the destroy applicant icon
    Then the user should see the popup for the remove applicant confirmation
