Feature: Super Admin staff create announcements for consumer role

  Scenario: Hbx staff create announcements for consumer role
    Given Super Admin exists
    When Super Admin logs on to the Hbx Portal
    And Super Admin should see the link of announcements and click
    Then Super Admin should see the page of announcements
    When Super Admin enter announcement info
    Then Super Admin should see the current announcement
    When Super Admin enter announcement info with future date
    Then Super Admin should not see the future announcement
    When Super Admin click the link of all
    Then Super Admin should see the future announcement
    When Super Admin enter announcement info with invalid params
    Then Super Admin should see the alert msg
    Then Super Admin logs out

  Scenario: Consumer see announcement for consumer role
    Given Announcement prepared for Consumer role
    Given Consumer role exists
    When Consumer login 
    Then Consumer should see announcement
    When Consumer click the link of documents
    Then Consumer should not see announcement
    When Consumer click the link of homepage
    Then Consumer should see announcement

  Scenario: Employer do not see announcement for consumer role
    Given Announcement prepared for Consumer role
    Given Employer role exists
    When Employer login 
    Then Employer should not see announcement

  Scenario: Hbx staff cannot create announcements for consumer role
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx admin should not see the link of announcements
    Then Hbx admin logs out