@js @screenshots
Feature: CSR finishes shopping for Individual
  Scenario: New insured user purchases on individual market
    Given Individual has not signed up as an HBX user
      When I visit the Insured portal
      Then Second user creates an individual account
      Then Second user goes to register as individual
      Then user clicks on continue button
      Then click continue again
      Then Second user should see a form to enter personal information
      Then user clicks on continue button
      Then Second user sees the Verify Identity Consent page
      Then Second user asks for help
      And Second user logs out
      When CSR accesses the HBX portal
      Then CSR should see the Agent Portal
      Then CSR should click on the Inbox tab
      Then CSR opens the most recent Please Contact Message
      Then CSR clicks on Resume Application via phone
      Then CSR should see identity verification page and clicks on submit
      Then CSR should see the dependents form
      And I click on the header link to return to CSR page
      Then CSR should see the Agent Portal
      Then CSR should click on the Families tab
      Then CSR clicks on New Consumer Paper Application
      Then CSR starts a new enrollment
