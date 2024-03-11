Feature: Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
    And the FAA feature configuration is enabled
    And the primary caretaker question configuration is enabled
    And FAA student_follow_up_questions feature is enabled
    Given a consumer, with a family, exists
    And the consumer is RIDP verified
    And is logged in
    And the user SSN is nil
    And the user has an eligible immigration status
    And the user has an age between 18 and 19 years old
    And the user will navigate to the FAA Household Info page
    And all applicants fill all pages except other questions
    And the user clicks Other Questions section on the left navigation
    And the user will navigate to the Other Questions page for the corresponding applicant

  Scenario: Foster care questions
    Given the user has an age between 18 and 26 years old
    Then the has this person ever been in foster care question should display

  Scenario: Foster care - answered yes
    Given the user has an age between 18 and 26 years old
    And the user answered yes to the has this person ever been in foster care question
    Then the where was this person in foster care question should display
    And the how old was this person when they left foster care question should display
    And the was this person enrolled in medicare when they left foster care should display