Feature: Employees plan shopping using QLE
  Employee DOB is after plan year start date but before the SEP effective date
  Employees can change plan or keep same plan with plan shopping using SEP

  Background: Setup site, employer, and benefit application
    Given the shop market configuration is enabled
    Given choose_shopping_method feature is disabled
    Given the osse subsidy feature is enabled
    Given all announcements are enabled for user to select
    Given a CCA site exists with a benefit market
    Given osse benefit market catalog exists for active initial employer with health benefits
    Given Qualifying life events are present
    And there is employer ABC Widgets with a OSSE eligibility

  Scenario: Employee Reports Qualifying Life Event (QLE) and Shops for a New Plan
    Given there exists Patrick Doe employee for employer ABC Widgets
    And initial employer ABC Widgets has active benefit application
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe of ABC Widgets has DOB after plan year start
    And employees for ABC Widgets have a selected coverage
    When Employee click the "Had a baby" in qle carousel
    And Employee select a current qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When employee clicked on shop for new plan
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the active plan year
    When Employee selects a last plan on the plan shopping page
    Then Patrick Doe should see summary page with qle effective date and new plan member premiums
    When Patrick Doe clicks the confirm link
    Then Patrick Doe should see receipt page with qle effective date and new plan member premiums
    Then Patrick Doe should see "my account" page with enrollment

  Scenario: Employee Reports Qualifying Life Event (QLE) and Maintains Current Plan
    Given there exists Patrick Doe employee for employer ABC Widgets
    And initial employer ABC Widgets has active benefit application
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe of ABC Widgets has DOB after plan year start
    And employees for ABC Widgets have a selected coverage
    When Employee click the "Had a baby" in qle carousel
    And Employee select a current qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When employee clicked on clicked on keep existing plan button
    Then Patrick Doe should see summary page with qle effective date and same plan member premiums
    When Patrick Doe clicks the confirm link
    Then Patrick Doe should see receipt page with qle effective date and same plan member premiums
    Then Patrick Doe should see "my account" page with enrollment

  Scenario: Employee shops with different products using previous button
    Given there exists Patrick Doe employee for employer ABC Widgets
    And initial employer ABC Widgets has active benefit application
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And employee Patrick Doe of ABC Widgets has DOB after plan year start
    And employees for ABC Widgets have a selected coverage
    When Employee click the "Had a baby" in qle carousel
    And Employee select a current qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When employee clicked on shop for new plan
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the active plan year
    When Employee selects a second plan on the plan shopping page
    Then Patrick Doe should see summary page with qle effective date and new plan member premiums
    When Patrick Doe clicks the previous link
    Then Patrick Doe should see the list of plans
    When Employee selects a last plan on the plan shopping page
    Then Patrick Doe should see summary page with qle effective date and new plan member premiums
    When Patrick Doe clicks the confirm link
    Then Patrick Doe should see receipt page with qle effective date and new plan member premiums
    Then Patrick Doe should see "my account" page with enrollment
