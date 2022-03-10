Feature: Drop Enrollment Members
    In order to drop enrollment members
    User should have the role of an admin

    Background:
      Given drop_enrollment_members feature is enabled
      Given User with multiple member enrollment exists
      Given Hbx Admin exists
      When Hbx Admin logs on to the Hbx Portal
      When Hbx Admin click Families link
      And Hbx Admin clicks Actions button
      And Hbx Admin clicks on the Drop Enrollment Members button

    Scenario: Admin selects a member to be dropped
      When Admin sets termination date for dropped members
      And Admin selects member to be dropped from enrollment
      And Admin submits drop enrollment member form
      Then Admin should see the dropped members

    Scenario: Admin selects multiple members to be dropped
      When Admin sets termination date for dropped members
      And Admin selects members to be dropped from enrollment
      And Admin submits drop enrollment member form
      Then Admin should see the dropped members

    Scenario: Admin selects no members to be dropped
      When Admin submits drop enrollment member form
      Then Admin should see that no members were selected to be dropped

    Scenario: Admin selects all members except a minor to be dropped
      When Admin sets termination date for dropped members
      And Admin selects all members except a minor to be dropped from enrollment
      And Admin submits drop enrollment member form
      Then Admin should see that the enrollment failed to terminate
