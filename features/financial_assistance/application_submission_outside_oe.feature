Feature: Consumer landing on SEP page outside of OE after continuing from the FAA eligibility results

  Background: Submit Your Application page
    Given the FAA feature configuration is enabled
    And FAA haven_determination feature is enabled
    # There needs to be a version of this with this instead
    # medicaid_gateway_determination
    And the user visits the portal outside OE
    And the user is on the FAA Household Info page
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page
    When the user clicks CONTINUE
    Then the user is on the Your Preferences page
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page


  Scenario: User continues from the eligibility results page outside of OE
    Given all required questions are answered including report change terms field
    And the user should be able to see medicaid determination question
    And the user has signed their name
    And the user clicks SUBMIT
    And the user waits for eligibility results
    And the user is on the Eligibility Response page
    When the user clicks on CONTINUE button
    Then the user should land on sep page