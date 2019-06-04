Feature: Add searchbox on broker agencies
  In order for the Hbx admin to search for broker agencies through searchbox

  Scenario: Search for a broker agency
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    Then Hbx Admin is on Broker Index of the Admin Dashboard
    When Hbx Admin is on Broker Index and clicks Broker Agencies
    Then Hbx Admin should see search box
    When he enters an broker agency name and clicks on the search button
    Then he should see the one result with the agency name
