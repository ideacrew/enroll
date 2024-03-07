Feature: Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
    Given the No SSN Dropdown feature is disabled
    And the FAA feature configuration is enabled
    And the primary caretaker question configuration is enabled
    And FAA student_follow_up_questions feature is enabled
    Given a consumer, with a family, exists
    And is logged in
    And the consumer is RIDP verified
    And the user SSN is nil
    And the user has an eligible immigration status
    And the user has an age between 18 and 19 years old
    And the user will navigate to the FAA Household Info page
    And all applicants fill all pages except other questions
    And the user clicks Other Questions section on the left navigation
    And the user will navigate to the Other Questions page for the corresponding applicant

  Scenario: SSN question
    Given the user SSN is nil
    And the user will navigate to the Other Questions page for the corresponding applicant
    And the have you applied for an SSN question should display
    And the user answers no to the have you applied for an SSN question
    Then the reason why question is displayed

  Scenario: SSN Dropdown
    Given the No SSN Dropdown feature is enabled
    Given the user SSN is nil
    And the user will navigate to the Other Questions page for the corresponding applicant
    And the have you applied for an SSN question should display
    And the user answers no to the have you applied for an SSN question
    Then the no ssn reason dropdown is displayed

  Scenario: Answered yes to military question
    Given the user answers yes to having an eligible immigration status
    And user answers no to the military veteran question
    Then the are you a spouse of such a veteran question should display

  Scenario: User gives no answer to blind, daily help, help with bills, and physically disabled
    Given the user fills out the required other questions and submits it
    Then the user should see text that the info is complete
