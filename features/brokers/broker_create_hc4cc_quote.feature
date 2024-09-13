Feature: Broker HC4CC quote creation

  Background: Broker Quoting Tool
    Given bs4_consumer_flow feature is disable
    Given the shop market configuration is enabled
    Given the osse subsidy feature is enabled
    And a CCA site exists with a benefit market
    And benefit market catalog exists with eligibility
    And Health and Dental plans exist
    And there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    Given Max Planck logs on to the Broker Agency Portal
    When Primary Broker clicks on the Employers tab
    And Primary Broker clicks on the Add Prospect Employer button
    And Primary Broker creates new Prospect Employer with default_office_location
    Then Primary Broker should see successful message
    Given prospect employer exist for District Brokers Inc
    And Primary broker clicks Actions dropdown and clicks Create Quote
    And Primary Broker enters quote name
    And Primary Broker should see HC4CC option
    Then Primary Broker selects quote as HC4CCC quote
    And Primary broker clicks on Select Health Benefits button
    And Primary broker should see metal level non bronze options

  Scenario: Broker should be able to create a quote for prospect employer with flexible rules
    And Primary broker selects plan offerings by metal level and enters 50 for employee and deps
    And Primary broker selects reference plan
    And Primary broker clicks on show details in employee costs section
    Then Primary broker should see plan names in employee costs
    Then Primary broker should see employee costs download pdf button
    Then Primary broker should see total HC4CC subcidy applied amount
    And Primary broker publishes the quote and sees successful message of published quote

  Scenario: Broker should be able to create a quote for prospect employer with no employee and dep contribution
    And Primary broker selects plan offerings by metal level and enters 0 for employee and deps
    And Primary broker selects reference plan
    And Primary broker clicks on show details in employee costs section
    Then Primary broker should see plan names in employee costs
    Then Primary broker should see employee costs download pdf button
    Then Primary broker should see total HC4CC subcidy applied amount
    And Primary broker publishes the quote and sees successful message of published quote

  Scenario: Broker should be able to create a copy of a quote with OSSE eligibility
    And Primary broker selects plan offerings by metal level and enters 50 for employee and deps
    And Primary broker selects reference plan
    And Primary broker clicks on show details in employee costs section
    Then Primary broker should see plan names in employee costs
    Then Primary broker should see employee costs download pdf button
    Then Primary broker should see total HC4CC subcidy applied amount
    And Primary broker publishes the quote and sees successful message of published quote
    Then Primary Broker clicks Back to All Quotes
    And the broker clicks Actions dropdown
    And the broker clicks copy quote
    And the broker should see Yes for HC4CC
    And Primary broker clicks on Select Health Benefits button
    Then Primary broker should see metal level non bronze options
