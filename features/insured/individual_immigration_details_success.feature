Feature: UI Validations for Document Type (Required/Optional) will match V37 VLP BSD

  Background: Singing up a consumer account and landing on the Personal information page
    Given Individual has not signed up as an HBX user
    When the user visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And the user sees Your Information page
    When the user registers as an individual
    When the individual clicks on the Continue button of the Account Setup page
    Then Individual logs out

  Scenario Outline: The ability to enter my document information for my <document type> Document and successfully validates the inputs
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual selects eligible immigration status
    Then Individual selects <document type> document and fills required details correctly
    Then Individual should see the <document type> document text
    Then Individual fills demographic details
    When Individual clicks on continue
    Then Individual does go to Authorization and Consent page
    Then Individual logs out

    Examples:
      | document type                     |
      | i327                              |
      | i551                              |
      | i571                              |
      | i766                              |
      | Certificate of Citizenship        |
      | Naturalization Certificate        |
      | Machine Readable Immigrant Visa   |
      | Temporary i551 Stamp              |
      | i94                               |
      | i94 in Unexpired Foreign Passport |
      | Unexpired Foreign Passport        |
      | i20                               |
      | DS2019                            |
      | Other With Alien Number           |
      | Other With i94 Number             |




