Feature: Consumer RIDP verification process

  Background: Individual RIDP Verification process
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal outside of open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    Then Individual sees previously saved address

  Scenario: New insured user chooses I Disagree on Auth and Consent Page
    Given that the Consumer has chosen “I Disagree” on the Auth and Consent page
    When the consumer tries to create their own account
    Then the consumer can’t navigate passed the doc upload page until proof of identity is uploaded and verified by the Admin

  Scenario:  New insured user chooses I Disagree on Auth and Consent Page and admin purchases his plan
    Given that the Consumer has chosen “I Disagree” on the Auth and Consent page
    When the consumer tries to create their own account
    Then Individual logs out
    When an HBX admin exists
    And Admin logs in the Hbx Portal
    When Admin click on families link
    Then Admin sees page with RIDP documents
    Then Admin should see the dependents form
    And I click on continue button on household info form
    When I click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When I click on continue button on group selection page during a sep
    And I select three plans to compare
    And I should not see any plan which premium is 0
    And I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    And I click on continue button to go to the individual home page
    And I should see the individual home page