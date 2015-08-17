@watir @screenshots
Feature: Insured Plan Shopping on Individual market
  Scenario: New insured user purchases on individual market
    Given Individual has not signed up as an HBX user
      When I visit the Insured portal
      Then Individual creates HBX account
      Then I should see a successful sign up message
      When user goes to register as an individual
      Then user should see the no match form with individual market option
      Then Individual should click on Individual market for plan shopping
      Then Individual should see a form to enter personal information
      When Individual clicks on continue button
      Then Individual should see identity verification page and clicks on submit
      Then Individual should see the dependents form
      And Individual clicks on add member button
      And I click on continue button on household info form
      And I click on continue button on group selection page
      And I select a plan on plan shopping page
      And I click on purchase button on confirmation page
      And I click on continue button to go to the individual home page
      And I should see the individual home page


