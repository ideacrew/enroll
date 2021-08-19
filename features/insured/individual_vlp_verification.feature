Feature: Insured VLP Verification for Individual market

  Background:
    Given Individual has not signed up as an HBX user
    When the user visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And the user sees Your Information page
    When the user registers as an individual
    When the individual clicks on the Continue button of the Account Setup page
    Then Individual should see heading labeled personal information
    And Individual selects eligible immigration status

  Scenario: Individual should be able to succesfully add a valid alphanumeric i94 number for I-94 (Arrival/Departure Record).
    Then selects the i94 document and fills required details correctly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    And the individual enters address information
    When Individual clicks on continue
    Then Individual does go to Authorization and Consent page

  Scenario: Individual should not be able to succesfully add an invalid alphanumeric i94 number for I-94 (Arrival/Departure Record).
    Then selects the i94 document and fills required details incorrectly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    And the individual enters address information
    When Individual clicks on continue
    Then Individual doesnot go to Authorization and Consent page

  Scenario: Individual should be able to succesfully add a valid alphanumeric i94 number for I-94 (Arrival/Departure Record) in Unexpired Foreign Passport.
    Then selects i94 unexpired foreign passport document and fills required details correctly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    And the individual enters address information
    When Individual clicks on continue
    Then Individual does go to Authorization and Consent page

  Scenario: Individual should not be able to succesfully add an invalid alphanumeric i94 number for I-94 (Arrival/Departure Record) in Unexpired Foreign Passport.
    Then selects i94 unexpired foreign passport document and fills required details incorrectly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    And the individual enters address information
    When Individual clicks on continue
    Then Individual doesnot go to Authorization and Consent page

  Scenario: Individual should be able to succesfully add a valid alphanumeric i94 number for Other With I-94 Number.
    Then selects Other With I-94 Number document and fills required details correctly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    And the individual enters address information
    When Individual clicks on continue
    Then Individual does go to Authorization and Consent page

  Scenario: Individual should not be able to succesfully add an invalid alphanumeric i94 number for Other With I-94 Number.
    Then selects Other With I-94 Number document and fills required details incorrectly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    And the individual enters address information
    When Individual clicks on continue
    Then Individual doesnot go to Authorization and Consent page
