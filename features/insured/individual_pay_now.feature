Feature: Individual pay now process

  Scenario: Outstanding verification
    Given Individual has not signed up as an HBX user
    Then Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    Then Individual click continue button
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And I click on continue button on household info form
    And I click on continue button on group selection page
    And I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    And I should click on pay now button
    And I should see model pop up
    And I should see Leave DC LINK buttton
    And I should be able to click  Leave DC LINK buttton