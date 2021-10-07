Feature: Email Address Feature
  Background: Setup permissions
    Given all permissions are present

  Scenario: user is on hbx home page and email address feature is enabled
    Given EnrollRegistry live_chat_widget feature is enabled
    When the user visits the HBX home page
    Then they should see the live chat button

  Scenario: user is on hbx home page and email address feature is disabled
    Given EnrollRegistry live_chat_widget feature is disabled
    When the user visits the HBX home page
    Then they should see the live chat button
