Feature: Functionality for the Family Relationships page for families with 2 dependents

  Background: Family Relationships page
    Given a consumer exists
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    And a user with a family with three dependents has a Financial Assistance application exists
    And financial assistance primary applicant logs in
    And user clicks CONTINUE
    Then the user will navigate to Family Relationships page
    Given that the user is on the FAA Family Relationships page

  Scenario: User should be 
    And all the relationships have been entered