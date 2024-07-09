Feature: Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
    Given bs4_consumer_flow feature is disable
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

  Scenario: Currently pregnant response with Yes with information filled and submitted
    Given the user answers yes to being pregnant
    Then the due date question should display
    And the user enters a pregnancy due date of one month from today
    And how many children question should display
    And the user answers two for how many children
    And the user fills out the rest of the other questions form and submits it
    Then the user should see text that the info is complete

  Scenario: Pregnancy response within 60 days Yes with information filled and submitted
    Given the user answers no to being pregnant
    And FAA post_partum_period_one_year feature is disabled
    And they answer yes to was this person pregnant in the last 60 days question
    And the user enters a pregnancy end date of one month ago
    And the user fills out the rest of the other questions form and submits it
    Then the user should see text that the info is complete

  Scenario: Pregnancy question - no
    Given the user answers no to being pregnant
    And FAA post_partum_period_one_year feature is disabled
    And was this person pregnant in the last 60 days question should display
    When they answer yes to was this person pregnant in the last 60 days question
    Then pregnancy end date question should display

  Scenario: If they were pregnant, were they on medicaid?
    Given the user answers no to being pregnant
    And FAA post_partum_period_one_year feature is disabled
    And they answer yes to was this person pregnant in the last 60 days question
    Then the has this person ever been in foster care question should display

  Scenario: If they were pregnant, were they on medicaid? Answer "Yes" with form submitted.
    Given the user answers no to being pregnant
    And FAA post_partum_period_one_year feature is disabled
    And they answer yes to was this person pregnant in the last 60 days question
    And the user enters a pregnancy end date of one month ago
    And the user fills out the rest of form with medicaid during pregnancy as yes and submits it
    And the info complete applicant has an attribute is_enrolled_on_medicaid that is set to true
    Then the user should see text that the info is complete