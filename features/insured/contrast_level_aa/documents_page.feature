Feature: Contrast level AA is enabled - Documents page

  Scenario: Consumer goes to the Documents page
    Given bs4_consumer_flow feature is enabled
    Given the contrast level aa feature is enabled
    And a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    When the consumer visits verification page
    Then the page passes minimum level aa contrast guidelines

  Scenario: Consumer has an FAA Application and income evidence present
    Given bs4_consumer_flow feature is disable
    Given the contrast level aa feature is enabled
    And the FAA feature configuration is enabled
    And a family with financial application and applicants in determined state exists with evidences
    And the consumer is logged in
    When the consumer visits verification page
    And there is a income evidence present with the option to upload a document
    Then the page passes minimum level aa contrast guidelines