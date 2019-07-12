Feature: Broker creates a quote for a prospect employer
  In order for Brokers to create a quote to Employers
  The Broker should be able to add Employer and Employees
  And Generate a quote

  Scenario: Broker should be able to create an Employer
    Given that a broker exists
    And the broker is signed in
    When broker visits the Employers tab
    And create a Prospect Employer
    And click on the Create Quote button
    Then the broker should be on the Roster page of a new quote
    And broker should see the quote roster is empty
