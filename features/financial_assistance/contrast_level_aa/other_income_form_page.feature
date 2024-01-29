# frozen_string_literal: true

Feature: Contrast level AA is enabled - unemployment and other income form page

  Background: User logs in and visits applicant's other income page
    Given the contrast level aa feature is enabled
    And a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    Given FAA income_and_deduction_date_warning feature is enabled
    Given divorce agreement year feature is disabled
    When the user will navigate to the FAA Household Info page
    Given ssi types feature is enabled
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant

  Scenario: User answers no to having other income
    Given the user answers no to having other income
    Then the other income choices should not show
    Then the page passes minimum level aa contrast guidelines

  Scenario: User answers yes to having other income
    Given the user answers yes to having other income
    Then the other income choices should show
    Then the divorce agreement copy should not show
    Then the page passes minimum level aa contrast guidelines

  Scenario: User enters negative Income amount for valid income type
    Given the user answers yes to having other income
    And the user checks capital gains checkbox
    And the user fills out the other income information with negative income
    Then the save button should be enabled
    And the user saves the other income information
    Then the page passes minimum level aa contrast guidelines
