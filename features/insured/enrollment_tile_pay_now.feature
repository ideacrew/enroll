Feature: User should be able to pay for plan

  Background: Hbx Admin navigates to create a user applications
  #   Given Hbx Admin exists
  #   When Hbx Admin logs on to the Hbx Portal
  #   And Hbx Admin creates a consumer application
  #   Then Hbx Admin logs out

  Scenario: User can see pay now button and pop up for gap between Kaiser enrollment
    Given EnrollRegistry kaiser_pay_now feature is enabled
    Given the FAA feature configuration is disabled
    Given individual Qualifying life events are present
    Given Patrick Doe has active individual market role and verified identity and IVL enrollment
    And Patrick Doe has HBX enrollment with future effective on date
    And user Patrick Doe logs into the portal
    When person should be able to see Actions dropdown
    Then person clicks on the Actions button
    Then person should the the First Payment button
