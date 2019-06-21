Feature: Check permissions for admin roles to access links in admin familes tab
  Scenario Outline:
    Given all permissions are present
    And that a user with a <role and subrole> exists and is logged in
    And user visits the Hbx Portal
	When user clicks on Families dropdown link
	Then the user should see <enabled options> options enabled in the families dropdown

  Examples:
    |role and subrole                       | enabled options        |
    | HBX staff role with HBX staff subrole |  all                   |        

# families_tab_access_steps.rb has some steps to continue with this.
# I also started making a method in user_world.rb called users_by_role which we may need to 
# serialize the roles steps
# The rest should be:      
# Scenario: Hbx Admin with hbx_read_only role should only see enabled outstanding verifications link in families dropdown
# Scenario: Hbx Admin with hbx_read_only role should only see enabled outstanding verifications link in families dropdown
# Scenario: Hbx Admin with hbx_csr_supervisor role should only see enabled new consumer application link in families dropdown
# Scenario: Hbx Admin with hbx_csr_tier2 role should only see enabled new consumer application link in families dropdown
# Scenario: Hbx Admin with hbx_csr_tier1 role should only see enabled new consumer application link in families dropdown