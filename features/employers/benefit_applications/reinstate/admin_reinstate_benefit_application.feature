Feature: As an admin user I should have the ability to click reinstate button on Employer datatable
  @flaky
  Scenario Outline: Admin clicks reinstate button under plan year dropdown for <aasm_state> benefit_application
    Given the shop market configuration is enabled
    Given the Reinstate feature configuration is enabled
    And a CCA site exists with a benefit market
    And benefit market catalog exists for <from_state> initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has <from_state> benefit application
    And initial employer ABC Widgets application <to_state>
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Plan Years button
    Then the user will select benefit application to reinstate
    When the user clicks Actions for that benefit application
    Then the user will see Reinstate button
    When Admin clicks on Reinstate button
    Then Admin will see Reinstate Start Date for <to_state> benefit application
    And Admin will see transmit to carrier checkbox
    When Admin clicks on Submit button
    Then Admin will see confirmation pop modal
    When Admin clicks on continue button for reinstating benefit_application
    Then Admin will see a Successful message
    And user logs out

  Examples:
    |  from_state |    to_state          |
    |   active    |   terminated         |
    |   active    | termination_pending  |
    |   active    | retroactive_canceled |
    |   active    |  canceled            |
