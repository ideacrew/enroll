Feature: Reset password of user
  In order to reset password of the user
  User should have the role of an admin

  Scenario: Admin can reset password of the user if has permission
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    Then there are 1 preloaded unlocked user accounts
    When Hbx Admin clicks on the User Accounts tab
    Then Hbx Admin should see the list of user accounts and an Action button
    When Hbx Admin clicks on the Action button
    Then Hbx Admin should see Reset Password link on user accounts page
    When Hbx Admin clicks on Reset Password link on user accounts page
    Then there is a confirm button should be visible
    When I click on the confirm button
    Then the reset password email should be sent to the user


  Scenario: Admin can add user email address to reset password if email does not exist
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    Then there are 1 preloaded user accounts without email
    When Hbx Admin clicks on the User Accounts tab
    Then Hbx Admin should see the list of user accounts and an Action button
    When Hbx Admin clicks on the Action button
    Then Hbx Admin should see Reset Password link on user accounts page
    When Hbx Admin clicks on Reset Password link on user accounts page
    Then there is a text field should be visible
    When I click on the confirm button
    Then an error Please enter a valid email should be raised
    And I fill the testuser email address for that user
    When I click on the confirm button
    Then an error Email is invalid should be raised
    And I fill the admin@dc.gov email address for that user
    When I click on the confirm button
    Then an error Email is already taken should be raised
    And I fill the testuser@email.com email address for that user
    When I click on the confirm button
    Then the user email should be testuser@email.com
    Then the reset password email should be sent to the user
