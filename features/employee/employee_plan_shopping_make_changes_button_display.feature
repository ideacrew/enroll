Feature: Make Changes Button Appears on Tile

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    Given Qualifying life events are present
    And there is an employer ABC Widgets
    Given there exists Patrick Doe employee for employer ABC Widgets
    And initial employer ABC Widgets has active benefit application
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal

  Scenario: Reporting a SEP and not finishing the enrollment SHOULD NOT cause "Make Changes" button to appear on the SEP enrollment tile
    And Patrick Doe has active coverage in coverage enrolled state
    When I click the "Had a baby" in qle carousel
    And I select current date as qle date
    Then I should see confirmation and continue
    When I click on continue button on household info form
    And I click the Shop for new plan button
    And I abandon shopping and clicks My Insured Portal to return to families home page
    # And I click the Back to My Account button
    Then the employee should not see the Make Changes button on their current enrollment tile

  Scenario: Purchasing an enrollment through SEP with active enrollment should NOT cause "Make Changes" button to appear on the SEp enrollment tile
    And Patrick Doe has active coverage in coverage enrolled state
    When Employee click the "Had a baby" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the active plan year
    When Employee selects a plan on the plan shopping page
    Then Patrick Doe should see coverage summary page with qle effective date
    Then Patrick Doe should see the receipt page with qle effective date as effective date
    Then Patrick Doe should see "my account" page with enrollment
    Then the employee should not see the Make Changes button on their current enrollment tile