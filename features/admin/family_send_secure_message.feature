Feature: As a Tier3 Admin I will have the ability to see and access "Send Secure Message" action on Families tab

  Background: Hbx Admin can Send Secure Message
    Given the shop market configuration is enabled
    Given a Hbx admin with hbx_tier3 role exists
    And a consumer exists
    And a Hbx admin logs on to Portal
    When Hbx Admin click Families link
    Then Hbx Admin should see the list of primary applicants and an Action button
    When Hbx Admin clicks Action button
    Then the user will see the Send Secure Message button
    When the user clicks the Send Secure Message button for this Person
    Then the Secure message form should have Subject and Content as required fields
    Then the user will see the Send Secure Message option form

  Scenario: HBX Staff with Tier3 Admin sub roles should be able to send message
    Then Admin enters form with subject and content and click send
    Then Should see a dialog box for confirmation
    Then Should click on confirm button
    Then Should see success message

  Scenario: HBX Staff with Tier3 Admin sub roles will be able to cancel at confirmation
    Then Admin enters form with subject and content and click send
    Then Should see a dialog box for confirmation
    Then Should click on cancel button
    Then Should not see a dialog box for confirmation

  Scenario: Secure message form should be closed out when Tier3 Admin sub roles click cancel button
    And the user clicks cancel button
    Then the user will not see the Send Secure Message option form
