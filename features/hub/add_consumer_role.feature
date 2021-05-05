@wip
Feature: Any Person with User account should be able to add consumer role

  Background: Setup site and benefit market catalog
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Xfinity Widgets

  Scenario Outline: User should be able to see add new consumer portal link
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits My Hub page
    Then person should see their <role> information under My Hub page
    And person clicks on Add Account tab
    And person clicks on INDIVIDUAL & FAMILY link on pop up
    Then person should see a pop up with text "Do you need financial assistance?"
    And on clicking the radio buttton and click Continue
    And person should see their indentifying information
    When user clicks on continue button
    Then user should see heading labeled personal information
    And person selects all mandatory radio option for us citizen
    And person goes to the next pages
    When I click on none of the situations listed above apply checkbox
    And I click on back to my account button
    Then I should land on home page
    And person with <role> signs in and visits My Hub page
    Then person should see My coverage link
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Resident       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |
