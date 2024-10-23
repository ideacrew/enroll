Feature: Enrollment History Page

  Consumer will be able to access Enrollments tab only when
  Enrollment History Page feature is enabled. When Enrollment History Page
  feature is disabled, consumer shall not be able see or access the
  Enrollment History Page page.

  Background:
    Given bs4_consumer_flow feature is disable
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp

  Scenario: Enrollment History Page Feature Is Disabled - Consumer can not see the Enrollments Link
    Given EnrollRegistry enrollment_history_page feature is disabled
    When consumer visits home page
    Then the consumer will not see the Enrollments link

  Scenario: Enrollment History Page Feature Is Enabled - Consumer can see the Cost Savings Link
    Given EnrollRegistry enrollment_history_page feature is enabled
    When consumer visits home page
    Then the Enrollments link is visible

  Scenario: Enrollment History Page Feature Is Enabled - Consumer can navigate to the Cost Savings Page
    Given EnrollRegistry enrollment_history_page feature is enabled
    Given consumer visits home page
    And the Enrollments link is visible
    When the consumer clicks the Enrollments link
    Then the consumer will navigate to the Enrollment History page