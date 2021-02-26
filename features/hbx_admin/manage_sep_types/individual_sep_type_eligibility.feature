Feature: Individual Qualifying life of event kind based on eligibity dates
  Background:
    Given all permissions are present
    Given individual Qualifying life events are present
    And Patrick Doe has active individual market role and verified identity

  Scenario: Consumer can qualify for Special enrollment period based on eligibity dates
    And user Patrick Doe logs into the portal
    And Individual should see listed individual market SEP Types
    And Individual should see the "Losing other health insurance" at the bottom of the ivl qle list
    When Individual click on the "Losing other health insurance" Sep Type 
    And Individual should see input field to enter the Sep Type date of event
    And Individual fill in QLE event Losing other health insurance date within the range eligiblity date period
    And Individual should see QLE date filled and clicks continue
    Then Individual should see sucess confirmation text
    And Individual should see the "Losing other health insurance" at the bottom of the ivl qle list
    And Individual should see input field to enter the Sep Type date of event
    And Individual fill in QLE event Losing other health insurance date outside the range eligiblity date period
    And Individual should see QLE date filled and clicks continue
    Then Individual should not see sucess confirmation text

  Scenario: Admin can view consumer qualified for special enrollment period based on eligibity dates
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    When Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click the name of Patrick Doe from family list
    Then I should land on home page
    And I should see listed individual market SEP Types
    And I should see the "Losing other health insurance" at the bottom of the ivl qle list
    When I click on the "Losing other health insurance" Sep Type
    And I should see input field to enter the Sep Type date of event
    And I fill in QLE event Losing other health insurance date within the range eligiblity date period
    And I should see QLE date filled and clicks continue
    And I should see QLE date filled and clicks continue
    Then I should see sucess confirmation text
    When Admin click on the "Entered into a legal domestic partnership" Sep Type
    And Admin should see input field to enter the Sep Type date of event
    And user visits the families home page
    And I fill in QLE event Losing other health insurance date outside the range eligiblity date period
    And Admin should see QLE date filled and clicks continue
    Then Admin should not see sucess confirmation text
    And Admin logs out