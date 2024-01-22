Feature: Live Chat Feature
  Background: Setup permissions
    Given all permissions are present

  Scenario: user is on hbx home page and live chat feature is enabled
    Given EnrollRegistry live_chat_widget feature is enabled
    Given EnrollRegistry external_qna_bot feature is disabled
    When the user visits the HBX home page
    And they click the live chat button
    And they see the live chat widget
    Then the page passes minimum level aa contrast guidelines

