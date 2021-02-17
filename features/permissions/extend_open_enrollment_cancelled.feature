@aca_shop_market_disabled
Feature: As a Super Admin I will be the only user
  that is able to see & access the "Extension of Open Enrollment" Feature.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for canceled initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has canceled benefit application

  Scenario: HBX Staff with Super Admin subroles should actionExtend Open Enrollment button
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user will see the Extend Open Enrollment button
    And the user clicks Extend Open Enrollment
    And the user clicks Edit Open Enrollment
    And the user fills out the Extend Open Enrollment form with a new date
    When the user clicks the Extend Open Enrollment to submit the form
    Then the user should see a success message that Open Enrollment was successfully extended