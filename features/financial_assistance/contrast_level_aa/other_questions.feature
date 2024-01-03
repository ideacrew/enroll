Feature: Contrast level AA is enabled - Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
    Given the contrast level aa feature is enabled
    And the FAA feature configuration is enabled
    And the primary caretaker question configuration is enabled
    And FAA student_follow_up_questions feature is enabled
    When a consumer, with a family, exists
    And is logged in
    And the user SSN is nil
    And the user has an eligible immigration status
    And the user has an age between 18 and 19 years old
    And the user will navigate to the FAA Household Info page
    And all applicants fill all pages except other questions
    And the user clicks Other Questions section on the left navigation
    And the user will navigate to the Other Questions page for the corresponding applicant

  Scenario: Before answering any questions
    Then the page should be axe clean excluding "a[disabled]" according to: wcag2aa; checking only: color-contrast

  Scenario: Currently pregnant response with Yes with information filled and submitted
    Given the user answers yes to being pregnant
    Then the due date question should display
    And the user enters a pregnancy due date of one month from today
    And how many children question should display
    And the user answers two for how many children
    Then the page should be axe clean excluding "a[disabled]" according to: wcag2aa; checking only: color-contrast
