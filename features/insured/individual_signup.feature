Feature: Insured Plan Shopping on Individual market

  Background:
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    And Individual market is under open_enrollment period

  Scenario: New insured user purchases on individual market and click on 'Make changes' button on enrollment
    Given there exists Patrick Doe with active individual market role and verified identity
    And Patrick Doe logged into the consumer portal
    When Patrick Doe click the "Married" in qle carousel
    And Patrick Doe selects a past qle date
    When Patrick Doe clicks continue from qle
    Then Patrick Doe should see family members page and clicks continue
    And Patrick Doe should see the group selection page
    And Patrick Doe clicked on shop for new plan
    And Patrick Doe select a plan on plan shopping page
    And Patrick Doe confirms on confirmation page
    When Patrick Doe click on continue on qle confirmation page
    And Patrick Doe should see the individual home page
    When Patrick Doe clicked on make changes button
    Then Patrick Doe should not see any plan which premium is 0
    Then Patrick Doe logs out

  Scenario Outline: Patrick Doe should not see document errors when not applying  and applying for coverage.
    Given Patrick Doe signed up as a consumer
    And Patrick Doe sees Your Information page
    And Patrick Doe should see heading labeled personal information
    And Patrick Doe register as an individual
    Then Patrick Doe clicks on the Continue button of the Account Setup page
    And Patrick Doe sees form to enter personal information
    Then Patrick Doe selects eligible immigration status
    And Patrick Doe selects <status> for coverage
    When Patrick Doe clicks on continue
    Then Patrick Doe should <action> error message Document Type cannot be blank
    Then Patrick Doe logs out
     Examples:
       | status            | action |
       | applying          | see    |
       | not applying      | not see |

  @flaky
  Scenario: Dependents should see document errors when proceeds without uploading document.
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    When Individual clicks on continue
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should be on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual edits dependent
    And Dependent selects applying for coverage
    And Dependent selects eligible immigration status
    And Individual clicks on confirm member
    Then Dependent should see error message Document type cannot be blank
    Then Individual logs out

  @flaky
  Scenario: Dependents should not see document errors when not applying for coverage.
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    When Individual clicks on continue
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should be on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual edits dependent
    And Dependent selects eligible immigration status
    And Dependent selects not applying for coverage
    And Individual clicks on confirm member
    Then Dependent should not see error message Document type cannot be blank
    Then Individual logs out

  @flaky
  Scenario: New insured user purchases on individual market during open enrollment and see a renewal enrollment generation with initial enrollment
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    When Individual click continue button
    And Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should be on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    And Individual should see the dependents form
    When I click on continue button on household info form
    And I click on continue button on group selection page
    And I select a plan on plan shopping page
    And I checks the Insured portal open enrollment dates
    And I click on purchase button on confirmation page
    And I click on continue button to go to the individual home page
    Then I should see a new renewing enrollment title on home page
    And I logs out
