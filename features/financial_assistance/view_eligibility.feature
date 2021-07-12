Feature: A dedicated page that visit the eligibility determination page

  Background: Submit Your Application page
    Given the FAA feature configuration is enabled

	Scenario: View Elibility link will be disabled in draft state
		Given that a user with a family has a Financial Assistance application in the "draft" state
		And the user navigates to the "Help Paying For Coverage" portal
		When the user clicks the "Action" dropdown corresponding to the "draft" application
		Then the "View Eligibility Determination" link will be disabled

	Scenario: View Elibility link will be disabled in "submitted" state
		Given that a user with a family has a Financial Assistance application in the "submitted" state
		And the user navigates to the "Help Paying For Coverage" portal
		When clicks the "Action" dropdown corresponding to the "submitted" application
		Then the "View Eligibility Determination" link will be disabled

	Scenario: View Elibility link will be disabled in "determination_response_error" state
		Given that a user with a family has a Financial Assistance application in the "determination_response_error" state
		And the user navigates to the "Help Paying For Coverage" portal
		When the user clicks the "Action" dropdown corresponding to the "determination_response_error" application
		Then the "View Eligibility Determination" link will be disabled

  Scenario: View Elibility link will be disabled in cancelled state
		Given that a user with a family has a Financial Assistance application in the "cancelled" state
		And the user navigates to the "Help Paying For Coverage" portal
		When the user clicks the "Action" dropdown corresponding to the "cancelled" application
		Then the "View Eligibility Determination" link will be disabled

  Scenario: View Eligibility Determination link will be actionable in the "terminated" state
		Given that a user with a family has a Financial Assistance application in the "terminated" state
		And the user navigates to the "Help Paying For Coverage" portal
		When clicks the "Action" dropdown corresponding to the "terminated" application
		Then the "View Eligibility Determination" link will be actionable

	Scenario: View Eligibility Determination link will be actionable in the "determined" state
		Given that a user with a family has a Financial Assistance application in the "determined" state
		And the user navigates to the "Help Paying For Coverage" portal
		When clicks the "Action" dropdown corresponding to the "determined" application
		Then the "View Eligibility Determination" link will be actionable

	Scenario: View Eligibility Determination link will be actionable and will navigate to the Eligibility Determination page
		Given that a user with a family has a Financial Assistance application in the "determined" state
		And the user navigates to the "Help Paying For Coverage" portal
		And clicks the "Action" dropdown corresponding to the "determined" application
		And clicks the "View Eligibility Determination" link
		Then the user will navigate to the Eligibility Determination page for that specific application

	Scenario: CSR Text should not display on the Eligibility Determination page if a family member is APTC eligible and has 0% CSR
		Given that a user with a family has a Financial Assistance application with tax households
		And the user has 0% CSR
		And the user navigates to the "Help Paying For Coverage" portal
		And clicks the "Action" dropdown corresponding to the "determined" application
		And clicks the "View Eligibility Determination" link
		Then the user will navigate to the Eligibility Determination page and will not find CSR text present

	Scenario: CSR Text should display on the Eligibility Determination page if a family member is APTC eligible and has 73% CSR
		Given that a user with a family has a Financial Assistance application with tax households
		And the user has a 73% CSR
		And the user navigates to the "Help Paying For Coverage" portal
		And clicks the "Action" dropdown corresponding to the "determined" application
		And clicks the "View Eligibility Determination" link
		Then the user will navigate to the Eligibility Determination page and will find CSR text present

  Scenario: External verification link
    Given FAA fa_send_to_external_verification feature is enabled
    Given that a user with a family has a Financial Assistance application with tax households
    And the user has a 73% CSR
    And the user navigates to the "Help Paying For Coverage" portal
    And clicks the "Action" dropdown corresponding to the "determined" application
    And all applicants are not medicaid chip eligible and are non magi medicaid eligible
    And clicks the "View Eligibility Determination" link
    Then the user should see the external verification link

