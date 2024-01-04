Feature: Functionality for the Family Relationships page - contrast level aa is enabled

  Background: Family Relationships page
    Given the contrast level aa feature is enabled
    And a consumer exists
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    And a financial assistance application and two applicants in info completed state exist
    And financial assistance primary applicant logs in
    And user clicks CONTINUE
    Then the user will navigate to Family Relationships page
    Given that the user is on the FAA Family Relationships page

  Scenario: Continue button enabled when all relationships are entered
    And there is a nil value for at least one relationship
    When the user populates the drop down with a value
    And the relationship is saved
    And the browser has finished rendering the page
    Then the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast


  Scenario: Missing value is highlighted
    And there is a nil value for at least one relationship
    And the family member row will be highlighted
    And the browser has finished rendering the page
    Then the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast