Feature: Contrast level AA is enabled - This is the final review page before submiting an application

  Background: Submit Your Application page
    Given the contrast level aa feature is enabled
    And a consumer exists
    And is logged in
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And all applicants are in Info Completed state
    And the user clicks CONTINUE
    And the user is on the Review Your Application page
    And the user clicks CONTINUE
    Then the user is on the Your Preferences page
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page
    Then the page passes minimum level aa contrast guidelines

  Scenario: Submit button is disabled when required checkboxes are checked but name is not signed
    Given all required questions are answered
    And the user has not signed their name
    Then the submit button will be disabled
    Then the page passes minimum level aa contrast guidelines

  Scenario: Submit button is enabled when required checkboxes are checked and name is signed
    Given all required questions are answered
    And the user has signed their name
    Then the submit button will be enabled
    Then the page passes minimum level aa contrast guidelines
