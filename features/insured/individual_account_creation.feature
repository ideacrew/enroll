Feature: UI validations for Email, Username, SSN already in use, and weak Password

  Background: New user vists consumer portal
    Given bs4_consumer_flow feature is disable
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    When Individual visits the Consumer portal during open enrollment

  Scenario: New user attempts to create account with email already in use
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When the Individual clicks CONTINUE
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
    When the Individual clicks CONTINUE
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
    When the Individual clicks CONTINUE
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
    And Individual should see the error message Invalid Social Security number

  Scenario: New user attempts to create account with invalid SSN and validate SSN feature is disabled
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When validate SSN feature is disabled
    When the user registers as an individual with invalid SSN
    When Individual clicks on continue
    And Individual should not see the error message Invalid SSN

  Scenario: Strong password feature is enabled
    Given the strong password length feature is enabled
    When Individual visits the Consumer portal during open enrollment
    When Individual creates a new HBX account with a weak password
    Then Individual should see a minimum password length of 12

  Scenario: Strong password feature is disabled
    Given the strong password length feature is disabled
    When Individual visits the Consumer portal during open enrollment
    When Individual creates a new HBX account with a weak password
    Then Individual should see a minimum password length of 8

  Scenario: Password field tooltip is displayed on focus and strong password length feature is disabled
    Given the strong password length feature is disabled
    When Individual focus on the password field
    Then Individual should see the password tooltip with text minimum characters 8

  Scenario: Suppress Tooltip Error for Passwords Under 20 Characters
    Given the strong password length feature is disabled
    When Individual focus on the password field
    When Individual enters the password
    Then Individual does not see the error on tooltip indicating a password longer than 20 characters

  Scenario: New user creates account with female gender
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual female gender
    When the Individual clicks CONTINUE
    Then Individual sees form to enter personal information with checked female gender
