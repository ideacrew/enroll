Feature: Individual market with duplicate enrollments

  Background: Individual account creation and enabling duplicate enrollment warning setting
    Given bs4_consumer_flow feature is disable
    Given an Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    Given the warning duplicate enrollment feature configuration is enabled
    When Individual visits the Consumer portal during open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    When Individual sees Your Information page
    And user registers as an individual
    And Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information
    
  Scenario: Individual adds dependent and shops for a plan. Dependent creates account, shops for a plan and sees duplicate enrollment warning
    When the individual clicks continue on the personal information page
    And Individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    And Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual clicks on Add New Person
    And Individual adds spouse dependent info
    Then Individual confirms dependent info
    When the Individual clicks CONTINUE
    And Individual clicks on the continue button
    And Individual selects a plan on plan shopping page
    And Individual clicks on purchase button on confirmation page
    Then Individual clicks on the Continue button to go to the Individual home page
    Then the individual logs out
    When Dependent visits the Consumer portal during open enrollment
    And Dependent creates a new HBX account
    And Dependent sees Your Information page
    When Dependent registers as an individual
    And the Individual clicks CONTINUE
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And the person named Spouse Smith is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And the Individual clicks CONTINUE
    And Individual clicks on the continue button
    And Individual selects a plan on plan shopping page
    Then Individual should see Duplicate Enrollment warning in the Confirmation page

  Scenario: Individual adds dependent. Dependent creates account and shops for a plan, Individual shops for a plan including dependent and sees duplicate enrollment warning
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual clicks on Add New Person
    And Individual adds spouse dependent info
    Then Individual confirms dependent info
    And the individual logs out
    When Dependent visits the Consumer portal during open enrollment
    And Dependent creates a new HBX account
    Then Dependent sees Your Information page
    When Dependent registers as an individual
    And the individual clicks on the Continue button of the Account Setup page
    And the individual clicks continue on the personal information page
    And Individual agrees to the privacy agreeement
    And the person named Spouse Smith is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And the Individual clicks CONTINUE
    And Individual clicks on the continue button
    And Individual selects a plan on plan shopping page
    And Dependent clicks on purchase button on confirmation page
    Then Individual clicks on the Continue button to go to the Individual home page
    And the individual logs out
    When Primary member visits the Consumer portal during open enrollment
    And Primary member logs back in
    And the user clicks on CONTINUE button
    And Individual clicks on continue button on Choose Coverage page
    And Individual selects a plan on plan shopping page
    Then Individual should see Duplicate Enrollment warning in the Confirmation page