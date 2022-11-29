Feature: Broker updating employer business info

  Background: Setup site, employer, and benefit application
    Given the shop market configuration is enabled
    Given the shop OSSE configuration is enabled
    Given all announcements are enabled for user to select
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And ABC Widgets employer has osse eligibility
    And initial employer ABC Widgets has draft benefit application
    And employer ABC Widgets hired broker Max Planck from District Brokers Inc

  Scenario: Broker should be able to update business info without affecting their OSSE eligibility
    When Max Planck logs on to the Broker Agency Portal
    And Primary Broker clicks on the Employers tab
    Then Primary Broker should see Employer ABC Widgets and click on legal name
    And Primary should see the Employer ABC Widgets page as Broker
    Then Primary Broker decides to Update Business information
    And Primary Broker person should not see OSSE eligibility details
    Then Primary Broker person clicked save on business info form
    And ABC Widgets employer should remain osse eligible
