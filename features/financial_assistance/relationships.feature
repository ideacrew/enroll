Feature: Relationship save and navigation

Background: realtionship page 
Given that the user has FAA Application
And the user has navigated to the FAA Household Info
And the system has solved for all possible relationship between household members
And there is a nil value for at least one relationship
When the user clicks Continue 
Then the user will navigate to the Household relationships page

Scenario: Given that the user is on the Household Relationships page
And their is a nil value for at least one relationship in page
Then the CONTINUE button will be disabled

Scenario: Given that the user is on the Household Relationships page
When the user enters nothing in the missing relationship drop down
And clicks ADD Relationship
Then an error will present reminding the user to populate the relationship

Scenario: Given that the user is on the Household Relationships page
When the user clicks ADD RELATIONSHIP
And the user the user selects a valid relationship in the drop down
Then a confirmation of save will display

Scenario: Given that the user is on the Household Relationships page
When the user clicks ADD RELATIONSHIP
And the user the user selects a valid relationship in the drop down
And another relationship pair has a nil value despite the save
Then that value pair will display

Scenario: Given that the user is on the Household Relationships page
And all relationships have been populated
And all applicant information is complete
When the user clicks CONTINUE
Then the user will navigate to the Review Your Application page