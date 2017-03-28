Feature: Shop for plan for an individual and terminated employee
  Scenario: User should land directly on special enrollment page for individual if OE has ended and person is not an active employee
    Given that open enrollment has ended for individual market
    When Individual visits the Insured portal outside of open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
    When user clicks on continue button to save personal information
    And Individual agrees to the privacy agreeement
    And Individual should see identity verification page and clicks on submit
    And Individual should see the dependents form
    When user clicks on continue button
    Then I should land on special enrollment period page
    When I click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When I click on continue button on group selection page during a sep
    Then I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    And I click on continue button to go to the individual home page
    When the person has an active consumer
    And does not have an active employee role
    And the user click the shop for plans
    Then I should land on special enrollment period page

  Scenario: User should land directly on special enrollment page for individual if OE has ended and person is an inactive employee
    Given that open enrollment has ended for deactivate employee market
    When Individual visits the Insured portal outside of open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
    When user clicks on continue button to save personal information
    And Individual agrees to the privacy agreeement
    And Individual should see identity verification page and clicks on submit
    And Individual should see the dependents form
    When user clicks on continue button
    Then I should land on special enrollment period page
    When I click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When I click on continue button on group selection page during a sep
    Then I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    And I click on continue button to go to the individual home page
    When the person has an active consumer
    And the person is a terminated employee
    And the user click the shop for plans
    Then I should land on special enrollment period page