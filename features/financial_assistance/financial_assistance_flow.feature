Feature:	A dedicated page that improves visibility & ensures that the user is making an educated election. 
	Background:
		Given that the user is applying for a CONSUMER role 
		And the primary member has supplied mandatory information required
		And the primary member authorizes the system to call EXPERIAN
		And system receives a positive response from EXPERIAN

	Scenario:	Primary Member Passes Experian Validation
		Given the user answers all VERIFY IDENTITY  questions
		When the user clicks submit
		And Experian returns a VERIFIED response
		Then The user will navigate to the Help Paying for Coverage page

  Scenario: User navigates forward without answering mandatory question
    Given the user is on the Help Paying For Coverage page
    When the user clicks CONTINUE
    And the answer to Do you want to apply for Medicaid… is NIL
    Then the user will remain on the page 
    And an error message will display stating the requirement to populate an answer