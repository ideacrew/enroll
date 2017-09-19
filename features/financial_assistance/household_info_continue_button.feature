Feature: A dedicated page that gives the user access to household member creation/edit as well as Financial application forms for each household member.

Background: Household Info page
Given that the user is on FAA Household Info: Family Members page

Scenario: CONTINUE button navigation
Given that the user is on the FAA Household Info: Family Members page
When at least one applicant is in the Info Needed state
Then the CONTINUE button will be disabled

Scenario: CONTINUE button navigation
Given that the user is on the FAA Household Info: Family Members page
When all applicants are in Info Completed state
Then the CONTINUE button will be ENABLED

Scenario: CONTINUE button navigation
Given that the user is on the FAA Household Info: Family Members page
When all applicants are in Info Completed state
And user clicks CONTINUE
Then the user will navigate to Family Relationships page


