Feature: can Transition family members
    
  Background: Hbx Admin can Transition family members
		Given a Hbx admin with hbx_staff role exists
		And a Hbx admin logs on to Portal
		And a consumer exists
		And the HBX admin visits the Dashboard page

		Scenario: Only Hbx Admin can view Transition family members link actions dropdown in families index page
			When Hbx Admin clicks on Families link
			Then Hbx Admin should see the list of primary applicants and an Action button
			When Hbx Admin clicks on the Action button
			Then Hbx Admin should see an Transition family members link

		Scenario: Transition family member from consumer role to cover all
			When Hbx Admin clicks on Families link
			Then Hbx Admin should see the list of primary applicants and an Action button
			When Hbx Admin clicks on the Action button
			Then Hbx Admin should see an Transition family members link
			When Hbx Admin clicks on Transition family members link
			And Hbx Admin should see the form being rendered to transition each family members seperately
			And Hbx Admin enter/update information of each member individually
			And Hbx Admin clicks on submit button
			And Hbx Admin should show the Transition Results and the close button
			When Hbx Admin clicks on close button
			Then Transition family members form should be closed
