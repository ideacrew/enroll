# frozen_string_literal: true

Feature: contrast level aa is enabled - A consumer should see the applications assistance year when feature enabled
  Background:
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    Given the contrast level aa feature is enabled
    And IAP Assistance Year Display feature is enabled
    When a consumer visits the Get Help Paying for coverage page
    And selects yes they would like help paying for coverage
    Then they should see a new finanical assistance application
    Then They should see the application assistance year above Info Needed
    Then the page passes minimum level aa contrast guidelines