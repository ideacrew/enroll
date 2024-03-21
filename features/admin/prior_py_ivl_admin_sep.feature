Feature: IVL consumer or Admin adding a SEP which falls in prior plan year,
  when a SEP is added successfully and consumer goes for Plan shopping
  with prior effective date then renewals will be generated in subsequent
  plan years(active year and future year(if IVL OE)) unless admin chooses not to renew the coverage

  Background: Setup IVL coverage periods, products and IVL consumer
    Given all permissions are present
    And the Prior PY IVL feature configuration is enabled
    And Admin IVL seps are present

  Scenario: Hbx Admin adding IVL sep in prior plan year for consumer with no
  prior or active coverage and renewal flag is checked

    Given Individual Market with no open enrollment period exists
    And Patrick Doe IVL customer with no health coverage exists
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And the person named Patrick Doe is RIDP verified
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    And I should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    And I click confirm on the plan selection page for Patrick Doe
    And Individual clicks on the Continue button to go to the Individual home page
    Then I see enrollments generated in prior year and current year


  Scenario: Hbx Admin adding IVL sep in prior plan year for consumer with no
  prior or active coverage and renewal flag is unchecked

    Given Individual Market with no open enrollment period exists
    And Patrick Doe IVL customer with no health coverage exists
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SEP is added with a prior year effective date
    And Coverage renewal flag is unchecked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And the person named Patrick Doe is RIDP verified
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    And I should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    And I click confirm on the plan selection page for Patrick Doe
    And Individual clicks on the Continue button to go to the Individual home page
    Then I see enrollment generated only in prior year

  Scenario: Hbx Admin adding IVL sep in prior plan year for consumer with active
  coverage but no prior coverage and renewal flag is checked

    Given Individual Market with no open enrollment period exists
    And Patrick Doe has a consumer role and IVL enrollment
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And the person named Patrick Doe is RIDP verified
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    And I should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    And I click confirm on the plan selection page for Patrick Doe
    And Individual clicks on the Continue button to go to the Individual home page
    Then I see enrollments generated in prior and current year, with active one canceled

  Scenario: Hbx Admin adding IVL sep in prior plan year for consumer with prior year
  expired coverage and active coverage and renewal flag is checked

    Given Individual Market with no open enrollment period exists
    And Patrick Doe has a consumer role with expired and active enrollment
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And the person named Patrick Doe is RIDP verified
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    And I should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    And I click confirm on the plan selection page for Patrick Doe
    And Individual clicks on the Continue button to go to the Individual home page
    Then I see enrollments generated in prior and current year, with active enr canceled and expired enr terminated

  Scenario: Hbx Admin adding IVL sep in prior plan year for consumer with no
  prior, active or renewal coverage and renewal flag is checked

    Given Individual Market with open enrollment period exists
    And Patrick Doe IVL customer with no health coverage exists
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And the person named Patrick Doe is RIDP verified
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    And I should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    And I click confirm on the plan selection page for Patrick Doe
    And Individual clicks on the Continue button to go to the Individual home page
    Then I see enrollments generated in prior, active and renewal plan years


  Scenario: Hbx Admin adding IVL sep in prior plan year for consumer with
  prior, active or renewal coverage and renewal flag is checked

    Given Individual Market with open enrollment period exists
    And Patrick Doe has a consumer role with prior expired active and renewal enrollment
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And the person named Patrick Doe is RIDP verified
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    And I should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    And I click confirm on the plan selection page for Patrick Doe
    And Individual clicks on the Continue button to go to the Individual home page
    Then I see enrollments generated in prior, active and renewal plan years with renewal enrollments canceled