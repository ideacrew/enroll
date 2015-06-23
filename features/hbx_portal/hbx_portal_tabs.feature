@watir @screenshots

Feature: HBX Portal Overview
  In order to administer HBX the tabs must show multiple views under the tabs.

  Scenario: Look at portal tabs
    When I visit the HBX portal to sign in
    When I sign in with valid Admin data

    When I select the tab Families
    Then I should see the header Families
    Then I select the tab Employers
    Then I select the tab Broker Agencies
    Then I select the tab Brokers

    Then I select the tab Issuers
    Then I select the tab Products
    Then I select the tab Configuration