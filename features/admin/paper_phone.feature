Feature: Phone and Paper Enrollment options exist
  In order to support paper and phone enrollments
  Links are provided that will track phone and paper enrollments

  Background:
    Given EnrollRegistry no_transition_families feature is enabled
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    When Hbx Admin click Families dropdown

  Scenario: Phone and Phone Enrollment
    Then Hbx Admin should see an DC Resident Application link
    Then I see the New Consumer Application link

  Scenario: Disabling Paper link
    Then the Paper action should not be actionable
