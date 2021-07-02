# frozen_string_literal: true

Feature: Start a new Financial Assistance Application
  Background:
    Given a consumer, with a family, exists
    And the FAA feature configuration is enabled
    And is logged in
    And a benchmark plan exists

  Scenario: A consumer wants to start a new financial assistance application
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And consumer clicks on pencil symbol next to primary person
    Then consumer should see today date and clicks continue

  Scenario: American Indian/ Alaskan Native Details feature is enabled
    Given AI AN Details feature is enabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And the user clicks Add Member
    And the user fills the the aplicant add member form with indian member yes
    Then the user should see the AI AN Details fields
    Then the user should see an error message for indian tribal state and name
