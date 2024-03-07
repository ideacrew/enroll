Feature: My Financial Assistance Applications page that visit the Review Application page
  Background: Review your application page
    Given a consumer exists with family
    And the consumer is RIDP verified
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
    And user should have an answer related to applicant

  Scenario: Review Application page shows Non SSN Apply Reason when Applicant has one
    Given that a family has a Financial Assistance application in the submitted state
    And an applicant has an existing non ssn apply reason
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the submitted application
    And the “Review Application” link will be actionable
    And clicks the “Review Application” link
    Then the user will navigate to the Review Application page
    And the user will see the applicant's is ssn applied answer
    And the user will see the applicant's non ssn apply reason

  Scenario: MVS Feature Is Enabled - Admin clicks on review application action and sees MVS question
    Given that a family has a Financial Assistance application in the determined state
    And FAA disable_employer_address_fields feature is enabled
    And FAA minimum_value_standard_question feature is enabled
    Given the consumer has a benefit
    And the consumer has an esi benefit
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the determined application
    And the “Review Application” link will be actionable
    And clicks the “Review Application” link
    Then the health plan meets mvs and affordable question should show

  Scenario: Admin clicks on Full application action, sees caretaker questions
    Given that a family has a Financial Assistance application in the submitted state
    When the primary caretaker question configuration is enabled
    When the primary caretaker relationship question configuration is enabled
    And an applicant has an existing non ssn apply reason
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the submitted application
    And the “Review Application” link will be actionable
    And clicks the “Review Application” link
    Then the user will navigate to the Review Application page
    Then the caretaker questions should show
