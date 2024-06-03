# frozen_string_literal: true

Feature: Contrast level AA is enabled - Start a new Financial Assistance Application and answers questions on health coverage page

  Background: User logs in and visits applicant's health coverage page
    Given the contrast level aa feature is enabled
    And the shop market configuration is enabled
    And a consumer, with a family, exists
    And is logged in
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And FAA display_medicaid_question feature is enabled
    When they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page (health coverage)
    And they visit the Health Coverage page via the left nav (also confirm they are on the Health Coverage page)

  Scenario: User answers no to currently having health coverage
    Given the user answers no to currently having health coverage
    Then the health coverage choices should not show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast

  Scenario: User answers no to currently having access to other health coverage
    Given the user answers no to currently having access to other health coverage
    Then the other health coverage choices should not show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast

  Scenario: User answers yes to currently having health coverage
    Given the user answers yes to currently having health coverage
    Then the health coverage choices should show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast

  Scenario: User answers yes to currently having access to other health coverage
    Given the user answers yes to currently having access to other health coverage
    Then the other health coverage choices should show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast

  Scenario: Health coverage form shows after checking an option (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a health coverage checkbox
    Then the health coverage form should show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast

  Scenario: Health coverage form shows after checking an option (currently have access to coverage)
    Given the user answers yes to currently having access to other health coverage
    And the user checks a health coverage checkbox
    Then the other health coverage form should show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast
