Feature: Insured Plan Shopping on Individual market Document Errors

  Background:
    Given bs4_consumer_flow feature is disable
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    When Individual visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When the individual clicks on the Continue button of the Account Setup page
    And Individual sees form to enter personal information

  Scenario: Individual should not see document errors when not applying for coverage.
    When Individual selects eligible immigration status
    And Individual selects not applying for coverage
    And Individual click continue button
    Then Individual should not see error message Document type cannot be blank
  
  Scenario: Individual should see document errors when proceeds without uploading document.
    When Individual selects eligible immigration status
    And Individual selects applying for coverage
    And Individual click continue button
    Then Individual should see error message Document Type: cannot be blank
   
  Scenario: Dependents should see document errors when proceeds without uploading document
    When the individual clicks continue on the personal information page
    And Individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual clicks on Add New Person
    And Individual fills in the form
    And Dependent selects applying for coverage
    And Dependent selects eligible immigration status
    And Individual clicks on confirm member
    Then Dependent should see error message Document type cannot be blank
    
  Scenario: Dependents should not see document errors when not applying for coverage
    When the individual clicks continue on the personal information page
    And Individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual clicks on Add New Person
    And Individual fills in the form
    And Dependent selects eligible immigration status
    And Dependent selects not applying for coverage
    And Individual clicks on confirm member
    Then Dependent should not see error message Document type cannot be blank