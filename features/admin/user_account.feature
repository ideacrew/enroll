Feature: User Account page
  In order for the Hbx admin to access user accounts

  Background: Setup permissions, HBX Admin, users, and organizations and employer profiles
    Given the shop market configuration is enabled
    Given all permissions are present
    And bs4_admin_flow feature is disable
    And that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And that a user with a Employee Role role exists and is not logged in
    And that a user with a Employer Role role exists and is not logged in
    And that a user with a Broker role exists and is not logged in

  Scenario Outline: Search for Employer by Role filter
    Given user visits the Hbx Portal
    And Hbx Admin click on User Accounts
    When I click <action> button
    Then I should <result>

    Examples:
      | action   | result                                 |
      | Employee | only see user with employee role       |
      | Employer | only see user with employer staff role |
      | Broker   | only see user with broker role         |
      | All      | see users with any role                |


  Scenario: Search for Employer by Locked filter
    Given user with Employee Role role is locked
    And user with Broker role is unlocked
    And user visits the Hbx Portal
    And Hbx Admin click on User Accounts
    When I click Employee and Locked button
    Then I should only see user with employee role

  Scenario: Search for Employer by Unlocked Filter
    Given user with Employee Role role is unlocked
    And user with Broker role is locked
    And user visits the Hbx Portal
    And Hbx Admin click on User Accounts
    When I click Employee and Unlocked button
    Then I should only see user with employee role

  Scenario: Search for User by OIM ID string
    Given user visits the Hbx Portal
    And Hbx Admin click on User Accounts
    And Hbx Admin should see search box
    When a user enters Employee Role user oim_id in search box
    Then a user should see a result with Employee Role user oim_id and not Broker user oim_id
    When a user enters Employee Role user email
    Then a user should see a result with Employee Role user email and not Broker user email

  Scenario: Should see subrole field on datatable
    Given user visits the Hbx Portal
    When Hbx Admin click on User Accounts
    Then I should see subrole field on datatable
