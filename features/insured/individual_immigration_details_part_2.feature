Feature: UI Validations for Document Type (Required/Optional) will match V37 VLP BSD

  Background: Singing up a consumer account and landing on the Personal information page
    Given bs4_consumer_flow feature is disable
    Given Individual has not signed up as an HBX user
    And EnrollRegistry tobacco_cost feature is disabled
    When the user visits the Consumer portal during open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And the user sees Your Information page
    And the user registers as an individual
    And the individual clicks on the Continue button of the Account Setup page
    
  Scenario Outline: The ability to enter my document information for my <document type> Document and successfully validates the inputs
    #Given Individual resumes enrollment
    #And Individual click on Sign In
    #And I signed in
    #Then Individual should see heading labeled personal information
    When Individual selects eligible immigration status
    And Individual selects <document type> document and fills required details correctly
    Then Individual should see the <document type> document text
    Then Individual fills demographic details
    When Individual clicks on continue
    Then Individual does go to Authorization and Consent page
    

    Examples:
      | document type                     |
      | i94                               |
      | i94 in Unexpired Foreign Passport |
      | Unexpired Foreign Passport        |
      | i20                               |
      | DS2019                            |
      | Other With Alien Number           |
      | Other With i94 Number             |




