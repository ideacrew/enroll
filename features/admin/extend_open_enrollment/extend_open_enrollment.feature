Feature: Super Admin & tier3 able to see & access "Extend Open Enrollment" Feature.

  Scenario Outline: HBX Staff with <subrole> subroles should/not be able to extend Open Enrollment for an Employer with a <aasm_state> plan year

    Given a Hbx admin with <subrole> role exists
    And a Hbx admin logs on to Portal
    And the employer has <aasm_state> plan year
    When Hbx Admin navigate to main page
    And Hbx Admin clicks on Employers link
    And the Hbx Admin clicks on the Action button
    And Hbx Admin should <action> an Extend Open Enrollment button

    Examples:
    | subrole     | aasm_state                      | action    |
    | super_admin | active                          | not see   |
    | super_admin | draft                           | not see   |
    | super_admin | enrolling                       | see       |
    | super_admin | canceled                        | see       |
    | super_admin | application_ineligible          | see       |
    | super_admin | enrollment_extended             | see       |
    | super_admin | enrolled                        | not see   |
    | super_admin | expired                         | not see   |
    | super_admin | terminated                      | not see   |
    | super_admin | termination_pending             | not see   |
    | hbx_tier3   | active                          | not see   |
    | hbx_tier3   | draft                           | not see   |
    | hbx_tier3   | enrolling                       | see       |
    | hbx_tier3   | canceled                        | see       |
    | hbx_tier3   | application_ineligible          | see       |
    | hbx_tier3   | enrollment_extended             | see       |
    | hbx_tier3   | enrolled                        | not see   |
    | hbx_tier3   | expired                         | not see   |
    | hbx_tier3   | terminated                      | not see   |
    | hbx_tier3   | termination_pending             | not see   |
    | super_admin | renewing_draft                  | not see   |
    | super_admin | renewing_enrolling              | see       |
    | super_admin | renewing_application_ineligible | see       |
    | super_admin | renewing_enrollment_extended    | see       |
    | super_admin | renewing_canceled               | see       |
    | super_admin | renewing_enrolled               | not see   |
    | hbx_tier3   | renewing_draft                  | not see   |
    | hbx_tier3   | renewing_enrolling              | see       |
    | hbx_tier3   | renewing_enrollment_extended    | see       |
    | hbx_tier3   | renewing_enrolling              | see       |
    | hbx_tier3   | renewing_enrolled               | not see   |
    | hbx_tier3   | renewing_canceled               | see       |



  Scenario: HBX Staff with super_admin subroles access Extend Open Enrollment button and able to entend 
  open enrollment date

    Given a Hbx admin with super_admin role exists
    And a Hbx admin logs on to Portal
    And the employer has application_ineligible plan year
    When Hbx Admin navigate to main page
    And Hbx Admin clicks on Employers link
    And the Hbx Admin clicks on the Action button
    And the Hbx Admin clicks Extend Open Enrollment
    And the Hbx Admin clicks Edit Open Enrollment
    Then the Choose New Open Enrollment Date panel is presented
    And the Hbx Admin enters a new open enrollment end date
    And the Hbx Admin clicks Extend Open Enrollment button
    Then a Successfully extended employer(s) open enrollment success message will display.
