Feature: Functionality for the Family Relationships page

  Background: Family Relationships page
    Given a consumer exists
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    And a financial assistance application and two applicants in info completed state exist
    And the user SSN is nil
    And financial assistance primary applicant logs in
    And user clicks CONTINUE
    Then the user will navigate to Family Relationships page
    Given that the user is on the FAA Family Relationships page

  Scenario: Navigation to Review Your Application page
    And there is a nil value for at least one relationship
    When the user populates the drop down with a value
    And the relationship is saved
    And all the relationships have been entered
    When the user clicks CONTINUE
    Then the user will navigate to the Review & Submit page

  Scenario: Continue button enabled when all relationships are entered
    And the user SSN is nil
    And there is a nil value for at least one relationship
    When the user populates the drop down with a value
    And the relationship is saved
    And all the relationships have been entered
    Then the CONTINUE button will be ENABLED

  Scenario: Correct left nav elements
    Then View My Applications left section WILL display
    Then Family Relationships left section WILL display
    And Review & Submit left section WILL display

  Scenario:  Missing value is highlighted
    And there is a nil value for at least one relationship
    Then the CONTINUE button will be disabled
    And the family member row will be highlighted

  Scenario: Family relationship value is stored
    And there is a nil value for at least one relationship
    When the user populates the drop down with a value
    Then the relationship is saved
