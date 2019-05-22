Feature: Super Admin & tier3 able to see & access "Extend Open Enrollment" Feature.

  Scenario Outline: HBX Staff with <subrole> subroles should <action> Extend Open Enrollmenth button
    Given a Hbx admin with <subrole> role exists
    And a Hbx admin logs on to Portal
    And the employer has application_ineligible plan year
	  When Hbx Admin navigate to main page
	  And Hbx Admin clicks on Employers link
	  And the Hbx Admin clicks on the Action button
	  And Hbx Admin should <action> an Extend Open Enrollment button

 		Examples:
      | subrole      				  | action  |
      | super_admin 				  | see     |
      | hbx_tier3					    | see     |
      | hbx_staff     				| not see |
      | hbx_read_only 				| not see |
      | hbx_csr_supervisor    | not see |
      | hbx_csr_tier2         | not see |
