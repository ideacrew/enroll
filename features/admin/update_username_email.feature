Feature: Update User Credentials
  In order to update DOB and SSN
  User should have the role of an admin

  Scenario: Admin enters valid credentials
    Given Hbx Admin Tier 3 exists
    When Hbx Admin Tier 3 logs on to the Hbx Portal
    Then Hbx Admin Tier 3 sees User Accounts link
    When Hbx Admin Tier 3 clicks on User Accounts link
    Then Hbx Admin Tier 3 should see the list of primary applicants and an Action button
    When Hbx Admin Tier 3 clicks on the Action button
    Then Hbx Admin Tier 3 should see an edit user link
    When Hbx Admin Tier 3 clicks on edit user link
    When Hbx Admin Tier 3 enters an valid credentials and clicks on submit
    Then Hbx Admin Tier 3 should see updated successfully message


  Scenario: Admin enters invalid credentials
    Given Hbx Admin Tier 3 exists
    When Hbx Admin Tier 3 logs on to the Hbx Portal
    Then Hbx Admin Tier 3 sees User Accounts link
    When Hbx Admin Tier 3 clicks on User Accounts link
    Then Hbx Admin Tier 3 should see the list of primary applicants and an Action button
    When Hbx Admin Tier 3 clicks on the Action button
    Then Hbx Admin Tier 3 should see an edit user link
    When Hbx Admin Tier 3 clicks on edit user link
    When Hbx Admin Tier 3 enters an invalid credentials and clicks on submit
    Then Hbx Admin Tier 3 should see error message
