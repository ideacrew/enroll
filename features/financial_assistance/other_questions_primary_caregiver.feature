Feature: Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
    Given bs4_consumer_flow feature is disable
    And the FAA feature configuration is enabled
    And the primary caretaker question configuration is enabled
    And FAA primary_caregiver_relationship_other_question feature is enabled
    Given a consumer, with a family, exists
    And is logged in
    And the consumer is RIDP verified
    And the user SSN is nil
    And the user has an age greater than 18 years old, with a young child 
    And the user will navigate to the FAA Household Info page
    And all applicants fill all pages except other questions
    And the user clicks Other Questions section on the left navigation
    And the user will navigate to the Other Questions page for the corresponding applicant

  Scenario: User answers yes to being a primary caregiver
    Given the user answers yes to being a primary caregiver
    Then the caregiver relationships should display

  Scenario: User answers no to being a primary caregiver
    Given the user answers no to being a primary caregiver
    Then the caregiver relationships should not display

  Scenario: User selects whom they are primary caregiver for
    Given the user answers yes to being a primary caregiver
    Then the caregiver relationships should display
    And the user selects an applicant they are the primary caregiver for
    Then an applicant is selected as a caregivee

  Scenario: User should see relationship options for caregiver
    Given the user answers yes to being a primary caregiver
    Then the caregiver relationships should display
    And the None of the above option should display