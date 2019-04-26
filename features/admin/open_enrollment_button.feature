Feature: As an <subrole> I <case> have the ability to extend the OE
  of a given Employer with a <aasm_state> enrollment.

  Scenario Outline: As an HBX Staff with <subrole> subroles I <case> be able to extend Open Enrollment for an Employer with a <aasm_state> benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for <aasm_state> initial employer with health benefits
    And there is an employer ABC Widgets
    Given employer ABC Widgets has <aasm_state> benefit application
    Given that a user with a HBX staff role with <subrole> subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will <action> the Extend Open Enrollment button

    Examples:
    | subrole       | aasm_state            | action    | case        |
    | Super Admin   | active                | not see   | should not  |
    | Super Admin   | draft                 | not see   | should not  |
    | Super Admin   | enrollment_closed     | see       | should      |
    | Super Admin   | canceled              | see       | should      |
    | Super Admin   | enrollment_ineligible | see       | should      |
    | Super Admin   | enrollment_extended   | see       | should      |
    | Super Admin   | enrollment_open       | see       | should      |
    | Super Admin   | enrollment_eligible   | not see   | should not  |
    | Super Admin   | enrollment_extended   | see       | should      |
    | Super Admin   | expired               | not see   | should not  |
    | Super Admin   | imported              | not see   | should not  |
    | Super Admin   | terminated            | not see   | should not  |
    | Super Admin   | termination_pending   | not see   | should not  |
