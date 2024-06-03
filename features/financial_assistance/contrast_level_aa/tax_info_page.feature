Feature: contrast level aa is enabled - Tax Info page meets AA compliance
    
  Scenario: contrast level aa is enabled - Tax Info page meets AA compliance
    Given a plan year, with premium tables, exists
    Given the FAA feature configuration is enabled
    Given the date is within open enrollment
	Given that the user is on the FAA Household Info page
	And the applicant has no saved data
	When the user clicks the ADD Info Button for a given household member
	Then the user will navigate to the Tax Info page for the corresponding applicant.
    Given the contrast level aa feature is enabled
	And the user is editing an application for financial assistance
	When the user navigates to the Tax Info page for a given applicant
    Then the page passes minimum level aa contrast guidelines