Feature: Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
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

  Scenario: Student question
    Then the is this person a student question should display

  Scenario: Student question - answered yes
    And the user answers yes to being a student
    Then the type of student question should display
    And student status end date question should display
    And type of school question should display