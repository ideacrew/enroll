Feature: Admin access to OSSE Audit-Log
  Scenario: Admin has access to OSSE Audit-Log under families home page
    Given EnrollRegistry aca_event_logging feature is enabled
    Given the shop market configuration is enabled
    Given all market kinds are enabled for user to select
    Given all permissions are present
    Given individual Qualifying life events are present
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has enrollment_open benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And Patrick Doe has a consumer role and IVL enrollment
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click the name of Patrick Doe from family list
    And the Admin should see Audit-Log button
    And user logs out

  Scenario: Admin has access to OSSE Audit-Log under employer home page
  Given EnrollRegistry aca_event_logging feature is enabled
    Given the shop market configuration is enabled
    Given all market kinds are enabled for user to select
    Given all permissions are present
    Given individual Qualifying life events are present
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has enrollment_open benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And Patrick Doe has a consumer role and IVL enrollment
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Employers tab
    Then the Admin is navigated to the Employers screen
    And I click the name of Abc Widgets from employers list
    And the Admin should see Audit-Log button
    And user logs out
