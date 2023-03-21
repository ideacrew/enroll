Feature: Broker employers table displays the HC4CC status of clients
    The Broker should be able to see the HC4CC eligibility status for employer clients

  Background: Set up employer, broker and their relationship
    Given the osse subsidy feature is enabled
    Given the shop market configuration is enabled
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And Health and Dental plans exist
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And this employer renewal application is under open enrollment
    And there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And employer ABC Widgets hired broker Max Planck from District Brokers Inc
    Given Max Planck logs on to the Broker Agency Portal

  Scenario: Broker should be able to see HC4CC status for ineligible employers
    When Primary Broker clicks the Employers tab
    Then The Employer's HC4CC eligibility should show Ineligible

  Scenario: Broker should be able to see HC4CC status for eligible employers
    Given employer ABC Widgets has OSSE eligibilities
    When Primary Broker clicks the Employers tab
    Then The Employer's HC4CC eligibility should show Eligible

  Scenario: Employer is a prospect client
    Given employer ABC Widgets is a prospect client
    When Primary Broker clicks the Employers tab
    Then The Employer's HC4CC eligibility should show Ineligible
