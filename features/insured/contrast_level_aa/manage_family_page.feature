# frozen_string_literal: true

Feature: Contrast level AA is enabled - existing consumer visits the manage family page
  Background:
    Given the contrast level aa feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    And consumer visits home page

  Scenario: the user visits the family tab
    Given individual clicks on the Manage Family button
    Then the page passes minimum level aa contrast guidelines

  Scenario: the user visits the personal tab
    Given individual clicks on the Manage Family button
    Then individual clicks on the Personal portal
    Then the page passes minimum level aa contrast guidelines
