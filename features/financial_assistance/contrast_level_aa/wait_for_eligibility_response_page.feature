Feature: Contrast level AA is enabled - The page that appears while the user is waiting for eligibility results to be returned

  Scenario: User is waiting for eligibility results
   Given bs4_consumer_flow feature is disable
    Given the contrast level aa feature is enabled
    And the FAA feature configuration is enabled
    And the user is on FAA Household Info: Family Members page
    And all applicants are in Info Completed state
    And the user clicks CONTINUE
    And the user is on the Review Your Application page
    And the user clicks CONTINUE
    Then the user is on the Your Preferences page
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page
    Given all required questions are answered
    And the user has signed their name
    And the submit button will be enabled
    And the user clicks SUBMIT
    Then the user should see the waiting for eligibility results page
    Then the page passes minimum level aa contrast guidelines
