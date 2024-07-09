Feature: This is the final review page before submiting an application

  Background: Submit Your Application page
    Given bs4_consumer_flow feature is disable
    Given a consumer exists with family
    And the consumer is RIDP verified
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

  Scenario: Submit button is disabled when a required checkbox is not checked and name is not signed
    Given a required question is not answered
    And the user has not signed their name
    Then the submit button will be disabled

  Scenario: Submit button is disabled when required checkboxes are checked but name is not signed
    Given all required questions are answered
    And the user has not signed their name
    Then the submit button will be disabled

  Scenario: Submit button is enabled when required checkboxes are checked and name is signed
    Given all required questions are answered
    And the user has signed their name
    Then the submit button will be enabled