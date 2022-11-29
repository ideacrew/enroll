Feature: Update employer business info

  Background: Setup site, employer, and benefit application
    Given the shop market configuration is enabled
    Given the shop OSSE configuration is enabled
    Given all announcements are enabled for user to select
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And ABC Widgets employer has osse eligibility
    And staff role person logged in

  Scenario: Employer should be able to update business info without affecting their OSSE eligibility
    When ABC Widgets is logged in and on the home page
    And staff role decides to Update Business information
    And staff role person should not see OSSE eligibility details
    Then staff role person clicked save on business info form
    And ABC Widgets employer should remain osse eligible
    And employer logs out
