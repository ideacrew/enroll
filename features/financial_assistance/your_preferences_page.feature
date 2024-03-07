Feature: User data usage preferences and voter registration

  Background: Your Preferences Page
    Given a consumer exists
    And is logged in
    And the user is RIDP verified
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    And the user is on the Review Your Application page
    And the user clicks CONTINUE
    Then the user is on the Your Preferences page

  Scenario: Defaulted to "I AGREE"
    And the answer to "To make it easier to determine my eligibility..." is defaulted to "I AGREE"
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page

  Scenario: User selects "I DISAGREE"
    Given the user selects I DISAGREE
    Then the "How long would you like your eligibility for premium reductions to be renewed? *" question displays
    When the user selects 3 years for eligibility length question
    And the user clicks CONTINUE
    Then the user is on the Submit Your Application page
    And the field corresponding to renewal should be defaulted to 3 years in the data model
