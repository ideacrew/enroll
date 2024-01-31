# frozen_string_literal: true

Feature: Start a new Financial Assistance Application
  Background:
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists

  Scenario: A consumer should see the applications assistance year when feature enabled
    Given IAP Assistance Year Display feature is enabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    Then They should see the application assistance year above Info Needed

  Scenario: A consumer should NOT see the applications assistance year when feature disabled
    Given IAP Assistance Year Display feature is disabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    Then They should not see the application assistance year above Info Needed

  Scenario: A consumer wants to start a new financial assistance application
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    And they should see each of their dependents listed
    And consumer clicks on pencil symbol next to primary person
    Then consumer should see today date and clicks continue

  @accessibility
  Scenario: contrast level aa is enabled - A consumer should see the applications assistance year when feature enabled
    Given the contrast level aa feature is enabled
    And IAP Assistance Year Display feature is enabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    Then They should see the application assistance year above Info Needed
    Then the page passes minimum level aa contrast guidelines
