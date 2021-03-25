Feature: Employee with current date of hire
    In order for the New Employee to purchase insurance
    Given Employer exists with active plan year
    Given New Employee is on the Census Employee Roster
    Given New Employee does not have a pre-existing person
    Then New Employee should be able to match Employer
    And Employee should be able to purchase Insurance

  Background: Setup site, employer, and benefit application
    Given the shop market configuration is enabled
    Given all announcements are enabled for user to select
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    Given Qualifying life events are present
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has enrollment_open benefit application
    And Acme Inc. employer has a staff role
    And there is a census employee record for Patrick Doe for employer Acme Inc.

  Scenario: New hire has enrollment period based on hired date
    Given staff role person logged in
    And Employee has current hired on date
    And Acme Inc. employer visit the Employee Roster
    Then Employer logs out
    Given Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    When Patrick Doe creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household Info: Family Members page and clicks Continue
    And Employee sees the Choose Coverage for your Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    And Employee sees the Enrollment Submitted page and clicks Continue
    Then Employee should see the "my account" page

    Given Acme Inc. eligibility rule has been set to first of month following or coinciding with date of hire
    Then Employee tries to complete purchase of another plan
    Then Employee should see the "my account" page

    Given Acme Inc. eligibility rule has been set to first of the month following date of hire
    Then Employee tries to complete purchase of another plan
    Then Employee should see the "my account" page

    Given Acme Inc. eligibility rule has been set to first of month following 30 days
    Then Employee tries to complete purchase of another plan
    Then Employee should see the "my account" page

    Given Acme Inc. eligibility rule has been set to first of month following 60 days
    Then Employee tries to complete purchase of another plan
    Then Employee should see the "my account" page

# Requires further testing if follwing still works in the same way:
# Given Acme Inc. eligibility rule has been set to first of month following or coinciding with date of hire
# Given Employee new hire enrollment window is closed
# When Employee clicks "Shop for Plans" on my account page
# When Employee clicks continue on the group selection page
# Then Employee should see "may not enroll until eligible" error message
