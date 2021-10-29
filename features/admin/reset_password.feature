Feature: Only HBX Staff will be able to see & access the Reset Password Feature.

  Scenario Outline: HBX Staff with <subrole> subroles should <action> Reset Password button
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And Qualifying life events are present
    Given that a user with a HBX staff role with <subrole> subrole exists and is logged in
    And the user is on the User Accounts tab of the Admin Dashboard
    Then user will click on action tab
    Then Hbx Admin should see Reset Password link in action drop down
    When Hbx Admin click on Reset Password link in action drop down

    Examples:
      | subrole       | action  |
      | HBX Staff     | see     |


  Scenario: Customer Service Representative without can_reset_password and can_lock_unlock cannot see reset password + Unlock / Lock Account
    Given a CCA site exists with a benefit market
    Given all permissions are present
    And hbx_csr_tier1 role permission can_access_user_account_tab is set to true
    And hbx_csr_tier1 role permission can_reset_password is set to false
    And hbx_csr_tier1 role permission can_lock_unlock is set to false
    Given that a user with a HBX CSR Tier1 role exists and is logged in
    And user visits user accounts path
    Then user will click on action tab
    Then Hbx Admin should not see Reset Password link in action drop down
    Then Hbx Admin should not see Unlock / Lock Account link in action drop down
    Then Hbx Admin should not see Edit User link in action drop down

