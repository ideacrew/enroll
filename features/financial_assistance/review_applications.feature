Feature: My Financial Assistance Applications page that visit the Review Application page
  Background: Review your application page
    Given a consumer exists
    And the FAA feature configuration is enabled
    And FAA display_medicaid_question feature is enabled
    And the primary caretaker question configuration is enabled
    And is logged in

  Scenario: Review Application link will be disabled in draft state
    Given that a family has a Financial Assistance application in the draft state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the draft application
    Then the "Review Application" link will be disabled

  Scenario: Review Application link will be disabled in cancelled state
    Given that a family has a Financial Assistance application in the cancelled state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the cancelled application
    Then the "Review Application" link will be disabled

  Scenario: Review Application link will be enabled in submitted state
    Given that a family has a Financial Assistance application in the submitted state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the submitted application
    Then the “Review Application” link will be actionable

  Scenario: Review Application link will be enabled in determination_response_error state
    Given that a family has a Financial Assistance application in the determination_response_error state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the determination_response_error application
    Then the “Review Application” link will be actionable

  Scenario: Review Application link will be enabled in determined state
    Given that a family has a Financial Assistance application in the determined state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the determined application
    Then the “Review Application” link will be actionable

  Scenario: Review Application link will be enabled in terminated state
    Given that a family has a Financial Assistance application in the terminated state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the terminated application
    Then the “Review Application” link will be actionable

  Scenario: Review Application link will be enabled in submitted state
    Given that a family has a Financial Assistance application in the submitted state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the submitted application
    And the “Review Application” link will be actionable
    And clicks the “Review Application” link
    Then the user will navigate to the Review Application page
    Then user should see Medicaid eligibility question
    And user should have feature toggled questions in review
    Then user should see need help paying question
    And user should have answer an related to applicant
