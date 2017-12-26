Feature: Check permissions for admin roles to access links in admin familes tab

  Scenario: Hbx Admin with hbx_staff role should see all links in families drop down
    Given a Hbx admin with hbx_staff role exists
    Given a Hbx admin logs on to Portal
	  When Hbx Admin navigate to main page
	  And admin should see families dropdown link in main tabs
	  And ciclks on families dropdown link in main tabs
	  Then all option are enabled in families dropdown

	 Scenario: Hbx Admin with hbx_read_only role should only see enabled outstanding verifications link in families dropdown
    Given a Hbx admin with hbx_read_only role exists
    Given a Hbx admin logs on to Portal
	  When Hbx Admin navigate to main page
	  And admin should see families dropdown link in main tabs
	  And ciclks on families dropdown link in main tabs
	  Then the only enabled option should be Outstanding Verifications

	Scenario: Hbx Admin with hbx_csr_supervisor role should only see enabled new consumer application link in families dropdown
    Given a Hbx admin with hbx_csr_supervisor role exists
    Given a Hbx admin logs on to Portal
	  When Hbx Admin navigate to main page
	  And admin should see families dropdown link in main tabs
	  And ciclks on families dropdown link in main tabs
	  Then the only enabled option should be New Consumer Application

	Scenario: Hbx Admin with hbx_csr_tier2 role should only see enabled new consumer application link in families dropdown
    Given a Hbx admin with hbx_csr_tier2 role exists
    Given a Hbx admin logs on to Portal
	  When Hbx Admin navigate to main page
	  And admin should see families dropdown link in main tabs
	  And ciclks on families dropdown link in main tabs
	  Then the only enabled option should be New Consumer Application

	Scenario: Hbx Admin with hbx_csr_tier1 role should only see enabled new consumer application link in families dropdown
    Given a Hbx admin with hbx_csr_tier1 role exists
    Given a Hbx admin logs on to Portal
	  When Hbx Admin navigate to main page
	  And admin should see families dropdown link in main tabs
	  And ciclks on families dropdown link in main tabs
	  Then the only enabled option should be New Consumer Application
