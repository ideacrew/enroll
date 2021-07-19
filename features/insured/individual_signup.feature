Feature: Insured Plan Shopping on Individual market

  Background:
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    And Individual market is under open_enrollment period

  Scenario: New user purchases on individual market and click on 'Make changes' button on enrollment
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

  Scenario Outline: Patrick Doe should not see document errors when not applying and applying for coverage.
    Given Patrick Doe signed up as a consumer
    And Patrick Doe sees Your Information page
    And Patrick Doe should see heading labeled personal information
    And Patrick Doe register as an individual
    Then Patrick Doe clicks on the Continue button of the Account Setup page
    And Patrick Doe sees form to enter personal information
    Then Patrick Doe selects eligible immigration status
    And Patrick Doe selects <status> for coverage
    When Patrick Doe click on continue button on the page
    Then Patrick Doe should <action> error message Document Type cannot be blank
    Then Patrick Doe logs out
     Examples:
       | status            | action |
       | applying          | see    |
       | not applying      | not see |

  Scenario Outline: Patrick Doe should see document errors when proceeds without uploading document with Dependents when not applying and applying for coverage.
    Given Patrick Doe signed up as a consumer
    And Patrick Doe sees Your Information page
    And Patrick Doe should see heading labeled personal information
    And Patrick Doe register as an individual
    Then Patrick Doe clicks on the Continue button of the Account Setup page
    And Patrick Doe sees form to enter personal information
    When Patrick Doe click on continue button on the page
    Then Patrick Doe agrees to the privacy agreeement
    Then Patrick Doe answers the questions of the Identity Verification page and clicks on submit
    Then Patrick Doe should be on the Help Paying for Coverage page
    Then Patrick Doe should see the dependents form
    And Patrick Doe clicks on add member button
    And Patrick Doe edits dependent
    And Patrick Doe selects eligible immigration status for dependent
    And Patrick Doe selects <status> for coverage
    And Patrick Doe clicks on confirm member
    Then Patrick Doe should <action> error message Document type cannot be blank
    Then Patrick Doe logs out
      Examples:
       | status            | action |
       | applying          | see    |
       | not applying      | not see |
