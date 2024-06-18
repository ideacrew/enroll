Feature: User add's new dependent and submit form after filling required fields

  Scenario: Add a dependent with missing relationship.
    Given bs4_consumer_flow feature is disable
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    When that the user is on FAA Household Info: Family Members page
    Then user clicks the Add New Person Button
    And user enters applicant name, ssn, gender and dob
    And user selects no for applicant's coverage requirement
    And user selects no for applicant's incarcerated status
    And user selects no for applicant's indian_tribe_member status
    And user selects yes for applicant's us_citizen status
    And user selects no for applicant's naturalized_citizen status
    And user clicks comfirm member
    Then form should not submit due to required relationship options popup
    And user fills in the missing relationship
    And user clicks comfirm member
    Then the applicant should have been created successfully