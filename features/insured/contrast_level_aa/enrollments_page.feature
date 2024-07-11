Feature: Contrast level AA is enabled - Enrollment History Page

  Background:
    Given bs4_consumer_flow feature is enabled
    Given the contrast level aa feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp

  Scenario: Enrollment History Page Feature Is Enabled - Consumer can navigate to the Cost Savings Page
    Given EnrollRegistry enrollment_history_page feature is enabled
    Given consumer visits home page
    And the Enrollments link is visible
    When the consumer clicks the Enrollments link
    Then the consumer will navigate to the Enrollment History page
    And the page passes minimum level aa contrast guidelines