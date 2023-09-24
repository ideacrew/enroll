Feature: EE with consumer role plan purchase

  # TODO: revisit code for background scenarios
  Background: Setup permissions, HBX Admin, users, and organizations and employer profiles
    Given enable change tax credit button is enabled
    Given the shop market configuration is enabled
    Given all announcements are enabled for user to select
    Given a resident role person with family
    Given an employer with initial application
    Given all products with issuer profile
    Then  an application provides health and dental packages
    Then there are sponsored benefit offerings for spouse and child
    When the user visits the Consumer portal during open enrollment

  Scenario: when user switches market place, effective date should be switched
    Given a matched Employee exists with resident role
    And system date is open enrollment date
    Then Employee sign in to portal
    When employee clicked on shop for plans
    When employee switched for employer-sponsored benefits
    Then user should see the effective date of employer-sponsored coverage
    When employee switched for coverall benefits
    Then user should see the effective date of individual coverage
    And system date is today's date