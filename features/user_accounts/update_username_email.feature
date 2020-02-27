Feature: As a Super Admin I will be able to
  update the username and/or email of a given user.

  Background: Setup site, admin user, and user
    Given a CCA site exists with a benefit market
    And an HBX admin exists
    And a user exists with employee role
    And a user exists with employer staff role
    And the HBX admin is logged in
    And the HBX admin is on the User Accounts page

  Scenario: Should see the Edit User option
    When the HBX admin searches for the given user
    Then the HBX admin should see the Edit User option

  Scenario: Can view the username and/or email of a given user
    When the HBX admin searches for the given user
    And the HBX admin selects the Edit User option
    Then the HBX Admin will see the Edit User Credentials

  Scenario: Can edit the username
    When the HBX admin searches for the given user
    And the HBX admin selects the Edit User option
    And the HBX admin updates the username for the user
    Then the HBX admin should receive an success message

  Scenario: Can edit the email
    When the HBX admin searches for the given user
    And the HBX admin selects the Edit User option
    And the HBX admin updates the email for the user
    Then the HBX admin should receive an success message

  Scenario: Can edit the email and username
    When the HBX admin searches for the given user
    And the HBX admin selects the Edit User option
    And the HBX admin updates the email and username for the user
    Then the HBX admin should receive an success message

  Scenario: Cant edit the username if username taken
    When the HBX admin searches for the given user
    And the HBX admin selects the Edit User option
    And the HBX admin updates the username with a username already in use
    Then an error message will appear stating that the credentials are currently in use
    And the error message will contain the First Name, Last Name, and HBX ID of the user that currently has the requested credentials

  Scenario: Cant edit the email if email taken
    When the HBX admin searches for the given user
    And the HBX admin selects the Edit User option
    And the HBX admin updates the email with a email already in use
    Then an error message will appear stating that the credentials are currently in use
    And the error message will contain the First Name, Last Name, and HBX ID of the user that currently has the requested credentials

  Scenario: Cant edit the username and email if both are taken
    When the HBX admin searches for the given user
    And the HBX admin selects the Edit User option
    And the HBX admin updates the email and username with a email and username already in use
    Then an error message will appear stating that the credentials are currently in use
    And the error message will contain the First Name, Last Name, and HBX ID of the user that currently has the requested credentials

  Scenario: Reset the Edit User Form
    When the HBX admin searches for the given user
    And the HBX admin selects the Edit User option
    And the users username and email appear in the form fields
    And the HBX Admin presses the Reset button on the Edit User form
    Then the text in the username and email address fields will be cleared

  Scenario: Search for user by first name
    When the HBX admin searches for the given user by first name
    Then the HBX admin should see the user in the search results

  Scenario: Search for user by last name
    When the HBX admin searches for the given user by last name
    Then the HBX admin should see the user in the search results

  Scenario: Search for user by full name
    When the HBX admin searches for the given user by full name
    Then the HBX admin should see the user in the search results

  Scenario: Search for user by id
    When the HBX admin searches for the given user by hbx id
    Then the HBX admin should see the user in the search results

  Scenario: Search for user by username
    When the HBX admin searches for the given user by username
    Then the HBX admin should see the user in the search results

  Scenario: Search for user by email
    When the HBX admin searches for the given user by email
    Then the HBX admin should see the user in the search results
