Feature: Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
    And the FAA feature configuration is enabled
    And FAA primary_caregiver_other_question feature is enabled
    And FAA primary_caregiver_relationship_other_question feature is enabled
    Given a consumer, with a family, exists
    And is logged in
    And the user has an age greater than 18 years old
    And the user will navigate to the FAA Household Info page
    And all applicants fill all pages except other questions
    And the user clicks Other Questions section on the left navigation
    And the user will navigate to the Other Questions page for the corresponding applicant

  Scenario: User is a primary caregiver with information filled and submitted
    Given the user answers yes to being a primary caregiver
    Then the caregiver relationships should display
    And the user select one or more applicants they are primary caregivers for
    And the user fills out the rest of the other questions form and submits it
    Then the user should see text that the info is complete

  Scenario: User is a primary caregiver with information filled and submitted
    Given the user answers yes to being a primary caregiver
    Then the caregiver relationships should display
    And the user does not select applicants they are primary caregivers for
    And the user fills out the rest of the other questions form and submits it
    Then the user should see text that the info is complete

  Scenario: User is not a primary caregiver
    Given the user answers no to being a primary caregiver
    And the user fills out the rest of the other questions form and submits it
    Then the user should see text that the info is complete