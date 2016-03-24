Feature: Hbx staff create announcements for consumer role

  Scenario: Hbx staff create announcements for consumer role
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx admin should see the link of announcements and click
    Then Hbx admin should see the page of announcements
    When Hbx admin enter announcement info
    Then Hbx admin should see the current announcement
    Then Hbx admin logs out
    Given Consumer role exists
    When Consumer login 
    Then Consumer should see announcement

