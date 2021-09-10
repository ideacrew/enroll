Feature: SHOP employee or Admin adding a SEP which falls in prior plan year,
  when a SEP is added successfully and employee goes for Plan shopping
  with prior effective date then renewals will be generated in subsequent
  plan years unless admin chooses not to renew the coverage

  Background: Setup Setup site, employer, and benefit applications in prior, active and renewal years
    Given the shop market configuration is enabled
    Given a DC site exists with a benefit market
    Given benefit market catalog exists for existing employer
    And the Prior PY SHOP feature configuration is enabled
    And Admin SHOP seps are present
    And there is an employer ABC Widgets
    And EnrollRegistry prior_plan_year_shop_sep feature is enabled
    

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with no
  prior or active coverage and renewal flag is checked and
  employer having expired and active py

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated in prior year and current year for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with no
  prior or active coverage and renewal flag is unchecked

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is unchecked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated only in prior year for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with active
  coverage but no prior coverage and renewal flag is checked

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe has employer sponsored enrollment in active py
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated in prior and current year, with active one canceled for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with active
  coverage and expired coverage and renewal flag is checked

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe has employer sponsored enrollment in active and expired py
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated in expired and active py, with existing active enr canceled and expired enr terminated for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with active
  coverage and expired coverage and renewal flag is unchecked

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe has employer sponsored enrollment in active and expired py
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is unchecked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated only in expired py with existing expired enr terminated for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with active
  coverage and expired coverage and renewal flag is checked

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and reinstated_active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe has employer sponsored enrollment in active and expired py
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated in expired and active reinstated py, with existing active enr canceled and expired enr terminated for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior reinstated expired plan year for employee with active
  coverage and expired coverage and renewal flag is checked

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has reinstated_expired and active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe has employer sponsored enrollment in active and expired py
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated in reinstated expired and active py, with existing active enr canceled and reinstated expired enr for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with no
  prior or active coverage and renewal flag is checked and
  employer having terminated and active py. Gap in coverage exists
  between active and prior terminated application

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has terminated and active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And a SEP is submitted
    Then I see a SEP error message for Patrick Doe

# TODO: enable this cucumber once terminated prior py is enabled in proj 200
#  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with
#  prior coverage and renewal flag is checked and
#  employer having terminated py with termination date exists in
#  last 12 months.
#
#    Given there exists Patrick Doe employee for employer ABC Widgets
#    And employer ABC Widgets has terminated benefit application
#    And employee Patrick Doe has past hired on date
#    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
#    And employee Patrick Doe has employer sponsored enrollment in terminated py
#    And Employee logs out
#    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
#    And Admin clicks Families tab
#    Then the Admin is navigated to the Families screen
#    When a SHOP SEP is added with a prior year effective date
#    And Coverage renewal flag is checked
#    And a SEP is submitted
#    Then confirmation popup is visible
#    When Admin clicks confirm on popup
#    Then I see a SEP success message for Patrick Doe
#    When I click the name of Patrick Doe from family list
#    And I click on Shop For Plans banner button
#    And I click Shop for new plan button on CHH page
#    When I selects a plan on the plan shopping page
#    When I clicks on Confirm button on the coverage summary page
#    Then I should see the enrollment submitted
#    When I click continue on enrollment submitted page
#    Then I see enrollments generated only in terminated py for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with
  no prior, active  or renewal coverage and renewal flag is checked and
  employer having expired, active and renewing py

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and active and renewal enrollment_open py's
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated expired, active and renewing py for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with
  prior, active coverage  and no renewal coverage and renewal flag is checked and
  employer having expired, active and renewing py

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and active and renewal enrollment_open py's
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe has employer sponsored enrollment in active and expired py
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated expired, active and renewing py with existing active enr canceled and expired enr terminated for Patrick Doe

  Scenario: Hbx Admin adding SHOP sep in prior plan year for employee with
  prior, active coverage  and renewal coverage and renewal flag is checked and
  employer having expired, active and renewing py

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employer ABC Widgets has expired and active and renewal enrollment_open py's
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe has employer sponsored enrollment in expired, active and renewal py
    And Employee logs out
    When that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    When a SHOP SEP is added with a prior year effective date
    And Coverage renewal flag is checked
    And a SEP is submitted
    Then confirmation popup is visible
    When Admin clicks confirm on popup
    Then I see a SEP success message for Patrick Doe
    When I click the name of Patrick Doe from family list
    And I click on Shop For Plans banner button
    And I click Shop for new plan button on CHH page
    When I selects a plan on the plan shopping page
    When I clicks on Confirm button on the coverage summary page
    Then I should see the enrollment submitted
    When I click continue on enrollment submitted page
    Then I see enrollments generated expired, active and renewing py with existing active and renewal enr canceled and expired enr terminated for Patrick Doe