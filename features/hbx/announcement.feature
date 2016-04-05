Feature: Hbx staff create announcements for consumer role

  Scenario: Hbx staff create announcements for consumer role
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx admin should see the link of announcements and click
    Then Hbx admin should see the page of announcements
    When Hbx admin enter announcement info
    Then Hbx admin should see the current announcement
    Then Hbx admin logs out

  Scenario: Consumer see announcement for consumer role
    Given Announcement prepared for Consumer role
    Given Consumer role exists
    When Consumer login 
    Then Consumer should see announcement

  Scenario: Employer do not see announcement for consumer role
    Given Announcement prepared for Consumer role
    Given Employer role exists
    When Employer login 
    Then Employer should not see announcement
