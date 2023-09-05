Feature: UI validations for Email, Username and SSN already in use 

  Background: New user vists consumer portal 
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    When Individual visits the Consumer portal during open enrollment
    
    
  Scenario: New user attempts to create account with email already in use
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When Individual clicks on continue
    And Individual sees form to enter personal information
    Then Individual logs out
    When Individual visits the Consumer portal during open enrollment
    And Individual creates an HBX account with email already in use
    Then Individual should see error message is already taken

    Scenario: New user attempts to create account with username already in use
    When Individual creates a new HBX account via username
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When Individual clicks on continue
    And Individual sees form to enter personal information
    Then Individual logs out
    When Individual visits the Consumer portal during open enrollment
    And Individual creates an HBX account with username already in use
    Then Individual should see error message is already taken

    Scenario: New user attempts to create account with SSN already in use
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When Individual clicks on continue
    And Individual sees form to enter personal information
    Then Individual logs out
    When Individual visits the Consumer portal during open enrollment
    And Individual creates an HBX account with SSN already in use
    Then Individual should see error message The Social Security number entered is associated with an existing user

  Scenario: New user attempts to create account with invalid SSN and validate SSN feature is enabled
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When validate SSN feature is enabled
    When the user registers as an individual with invalid SSN
    When Individual clicks on continue
    And Individual sees the error message Invalid SSN

  Scenario: New user attempts to create account with invalid SSN and validate SSN feature is disabled
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When validate SSN feature is disabled
    When the user registers as an individual with invalid SSN
    When Individual clicks on continue
    And Individual should not see the error message Invalid SSN