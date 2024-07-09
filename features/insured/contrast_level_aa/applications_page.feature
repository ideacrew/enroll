Feature: Contrast level AA is enabled - Consumer goes to the applications page
  Scenario: Consumer visits the Applications Page
    Given bs4_consumer_flow feature is enabled
    Given the contrast level aa feature is enabled
    Given a consumer exists
    And the consumer is logged in
    When the user visits the applications page
    Then the page passes minimum level aa contrast guidelines
