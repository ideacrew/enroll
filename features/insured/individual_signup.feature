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
      When Individual clicks on add member button

