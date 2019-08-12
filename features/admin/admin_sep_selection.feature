Feature: Update DOB and SSN

  Scenario: Admin purchases the an insured user through sep
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And all qualifying life event kinds are visible to customer
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual again clicks on add member button #TODO re-write this step
    And I click on continue button on household info form
    And I click on continue button on group selection page
    And I select three plans to compare
    And I should not see any plan which premium is 0
    And I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    When I click the "Had a baby" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    Then I can see the error message Please Select Effective Date
    And I select a effective date from list
    And I click on continue button on select effective date
    When I click on continue button on household info form

  Scenario: Admin attempts to purchase the an insured user through sep, but sep not visible
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And all qualifying life event kinds are not visible to customer
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual again clicks on add member button #TODO re-write this step
    And I click on continue button on household info form
    And I click on continue button on group selection page
    And I select three plans to compare
    And I should not see any plan which premium is 0
    And I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    Then I should not see "Had a Baby" in qle carousel

