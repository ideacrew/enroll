  Feature: Super Admin & tier3 able to see & access "Close Open Enrollment" Feature.

  Scenario Outline: HBX Staff with super_admin subroles access End Open Enrollment button and able to end 
  open enrollment only if plan year is in enrollment_extended or renewing_enrollment_extended states

    Given a Hbx admin with super_admin role exists
    And a Hbx admin logs on to Portal
    And the employer has <aasm_state> plan year
    When Hbx Admin navigate to main page
    And Hbx Admin clicks on Employers link
    And the Hbx Admin clicks on the Action button
    Then Hbx Admin should <action> an Close Open Enrollment button

    Examples:
    | aasm_state                      | action    |
    | active                          | not see   |
    | draft                           | not see   |
    | enrolling                       | not see   |
    | canceled                        | not see   |
    | application_ineligible          | not see   |
    | enrollment_extended             | see       |
    | enrolled                        | not see   |
    | expired                         | not see   |
    | terminated                      | not see   |
    | termination_pending             | not see   |
    | renewing_draft                  | not see   |
    | renewing_enrolling              | not see   |
    | renewing_application_ineligible | not see   |
    | renewing_enrollment_extended    | see       |
    | renewing_enrolled               | not see   |

  Scenario: HBX Staff with super_admin subroles access Close Open Enrollment button and able to close 
  open enrollment date

    Given a Hbx admin with super_admin role exists
    And a Hbx admin logs on to Portal
    And the employer has enrollment_extended plan year
    When Hbx Admin navigate to main page
    And Hbx Admin clicks on Employers link
    And the Hbx Admin clicks on the Action button
    And the Hbx Admin clicks Close Open Enrollment
    And the Hbx Admin clicks Close Open Enrollment button
    Then a Successfully closed employer(s) open enrollment success message will display.

