# frozen_string_literal: true

Feature: Start a new Financial Assistance Application
  Background:
    Given bs4_consumer_flow feature is disable
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the consumer is RIDP verified

  Scenario: No Coverage Tribe Details feature is enabled
    Given No coverage tribe details feature is enabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And the user clicks Add Member
    And the user selects not applying for coverage
    Then user should still see the member of a tribe question

  Scenario: Indian Alaskan Tribe Details feature is enabled
    Given AI AN Details feature is enabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And the user clicks Add Member
    And the user fills the applicant add member form with indian member yes
    And the user clicks submit applicant form
    Then the user should see the AI AN Details fields
    Then the user should see an error message for indian tribal state and name

  Scenario: Indian Alaskan Tribe Details feature is disabled
    Given AI AN Details feature is disabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And the user clicks Add Member
    And the user fills the applicant add member form with indian member yes
    And the user clicks submit applicant form
    Then the user should see an error message for indian tribal id

  Scenario: Featured Tribes Selection feature is enabled
    Given AI AN Details feature is enabled
    Given Featured Tribe Selection feature is enabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And the user clicks Add Member
    And the user fills the applicant add member form with indian member yes
    And the user selects tribal state from drop down
    Then the user should see tribe checkbox options

  Scenario: Featured Tribes Selection feature is disabled
    Given AI AN Details feature is enabled
    Given Featured Tribe Selection feature is disabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And the user clicks Add Member
    And the user fills the applicant add member form with indian member yes
    And the user selects tribal state from drop down
    And the user clicks submit applicant form
    Then the user should see an error message for indian tribal name

  Scenario: Indian Alaskan Tribe Details feature is enabled and user enters a name with a number
    Given AI AN Details feature is enabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And the user clicks Add Member
    And the user fills the applicant add member form with indian member yes
    And the user enters a tribal name with a number
    And the user clicks submit applicant form
    Then the user should see an error for tribal name containing a number


