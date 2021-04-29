Feature: Functionality for Applicant Validation

  Background: Household info page
    Given a consumer exists
    And is logged in
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page

  Scenario: applicant validation with no input for Tribal Id
    Given the primary member exists
    And at least a household members exist
    Then the user clicks on confirm member
    Then the user Should see an error message for Tribal Id