# frozen_string_literal: true

Feature: Contrast level AA is enabled - job and self employed income form page

  Background: User logs in and visits applicant's Job income page
    Given the contrast level aa feature is enabled
    And EnrollRegistry crm_update_family_save feature is disabled
    And EnrollRegistry crm_publish_primary_subscriber feature is disabled
    And a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    Given FAA income_and_deduction_date_warning feature is enabled
    When the user will navigate to the FAA Household Info page
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the applicant's Job income page

  Scenario: User reaches the income form page
    Given the user is on the Job Income page
    Then the page passes minimum level aa contrast guidelines

  Scenario: User answers yes to having self employment income
    Given the user answers yes to having self employment income
    Then self employment form should show
    Then the page passes minimum level aa contrast guidelines
