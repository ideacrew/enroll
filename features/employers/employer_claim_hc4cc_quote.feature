Feature: Employer HC4CC quote claim

  Background: Broker Quoting Tool
    Given the osse subsidy feature is enabled
    Given the shop market configuration is enabled
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And Health and Dental plans exist
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And employer ABC Widgets hired broker Max Planck from District Brokers Inc
    Given Max Planck logs on to the Broker Agency Portal
    When Primary Broker clicks the Employers tab
    And Primary broker clicks Actions dropdown and clicks Create Quote
    And Primary Broker enters a new quote name
    And Primary Broker selects Yes for HC4CC quote
    And Primary broker clicks on Select Health Benefits button
    And Primary broker selects plan offerings by metal level and enters 50 for employee and deps
    And Primary broker publishes the quote and sees successful message of published quote
    And broker logs out

  Scenario: Employer should be able to claim an HC4CC quote when eligible
    Given employer ABC Widgets is OSSE eligible
    Given that a user with a Employer role exists and is logged in
    And user only has employer staff roles
    And ABC Widgets goes to the benefits tab I should see plan year information
    # Temp step fix for failure when test run in batch
    And employer has correct reference plan id
    And the employer clicks on claim quote
    Then employer enters claim code for HC4CC quote
    When the employer clicks claim code
    Then the employer sees a successful message

  Scenario: Employer should not be able to claim an HC4CC quote when ineligible
    Given that a user with a HBX staff role with hbx staff subrole exists and is logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    And the employer clicks on claim quote
    Then employer enters claim code for HC4CC quote
    When the employer clicks claim code
    Then the employer sees a claim failure message
