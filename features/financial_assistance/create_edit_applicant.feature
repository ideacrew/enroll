Feature: User can create/edit personal info (dob, address, etc.) of applicant and submit form after correcting errors

  Background: Household Info page
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    When that the user is on FAA Household Info: Family Members page
    When the user clicks ADD/EDIT INCOME & COVERAGE INFO button for a given household member
    Then the user will navigate to the Tax Info page for the corresponding applicant.

  Scenario: Submit dependent applicant missing some info, correct errors, and submit form.
    Given that the user is on the Tax Info page for a given applicant
    When the user clicks My Household section on the left navigation
    Then the user will navigate to the FAA Household Info page for the corresponding application.
    When user clicks the Add New Person Button
    And user enters applicant info WITHOUT tribal member us citizen or naturalization status and submits form
    And user will have to accept alert pop ups for missing fields
    And user fills in the missing fields and clicks submit
    Then the applicant should have been created successfully