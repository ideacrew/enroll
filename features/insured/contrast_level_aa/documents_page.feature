Feature: Consumer goes to the Documents page

  Scenario: Consumer can see the text on left to the Navigation Button
    Given the contrast level aa feature is enabled
    Given a consumer exists
    And the consumer is logged in
    When the consumer visits verification page
    And the user navigates to the DOCUMENTS tab
    Then the page passes minimum level aa contrast guidelines