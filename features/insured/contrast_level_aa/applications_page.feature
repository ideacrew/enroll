Feature: Contrast level AA is enabled - Consumer goes to the applications page
  Scenario: Consumer visits the Applications Page
    Given the contrast level aa feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    Given EnrollRegistry enrollment_history_page feature is enabled
    Given consumer visits home page
    And the Applications link is visible
    When the consumer clicks the Applications link
    Then the page passes minimum level aa contrast guidelines
