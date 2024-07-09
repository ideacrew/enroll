Feature: Individual ability to update family information

  Background: Individual setup
    Given bs4_consumer_flow feature is disable
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    And consumer visits home page

  Scenario: Individual updates personal address
    Given individual has a home and mailing address
    Then individual clicks on the Manage Family button
    Then individual clicks on the Personal portal
    Then individual removes mailing address
    And individual edits home address
    And individual saves personal information changes
    Then information should be saved successfully

  Scenario: Individual updates gender
    Given an individual has gender information as male
    Then individual clicks on the Manage Family button
    Then individual clicks on the Personal portal
    And the individual selects gender as female
    And individual saves personal information changes
    Then the individual should show gender as female
