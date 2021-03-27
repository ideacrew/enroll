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