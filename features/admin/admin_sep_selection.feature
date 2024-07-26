Feature: Admin plan shopping via SEP
  Scenario: Admin can select plan for insured multiple role user through SEP
    Given the shop market configuration is enabled
    Given all market kinds are enabled for user to select
    Given all announcements are enabled for user to select
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
    And the person named Patrick Doe is RIDP verified
    And I should see the individual home page
    And I click Individual QLE events in QLE carousel
    When I click the "Had a baby" in qle carousel
    And I selects a current qle date
    Then I should see confirmation and continue
    And the Individual clicks CONTINUE
    Then I should see Shop for new plan button

  Scenario: Dual Role User will not see ivl warning message when shopping in Shop flow
    Given the shop market configuration is enabled
    Given all market kinds are enabled for user to select
    Given all announcements are enabled for user to select
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
    And Admin updates the address to Non DC Address
    And Admin clicks on shop for employer sponsored insurance
    Then Admin should not see the error text related to non dc address

