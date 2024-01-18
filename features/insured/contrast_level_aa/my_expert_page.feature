# frozen_string_literal: true

Feature: Contrast level AA is enabled - existing consumer visits the my expert page
  Background:
    Given the contrast level aa feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    And consumer visits home page

  Scenario: the user visits the my expert page
    Given individual clicks on the my expert button
    Then the page passes minimum level aa contrast guidelines
