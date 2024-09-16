Feature: Live Chat Feature
  Background: Setup permissions
    Given all permissions are present

  Scenario: user is on hbx home page and live chat feature is enabled
      Given bs4_consumer_flow feature is enabled
      Given EnrollRegistry live_chat_widget feature is enabled
      Given EnrollRegistry external_qna_bot feature is disabled
      When the user visits the HBX home page
      Then they should see the live chat button

  Scenario: user is on hbx home page and live chat and qna bot features are enabled
      Given bs4_consumer_flow feature is enabled
      Given EnrollRegistry live_chat_widget feature is enabled
      Given EnrollRegistry external_qna_bot feature is enabled
      When the user visits the HBX home page
      Then they should not see the live chat button
      Then they should see the bot button

    Scenario: user is on hbx home page and live chat feature is disabled
      Given EnrollRegistry live_chat_widget feature is disabled
      When the user visits the HBX home page
      Then they should not see the live chat button
