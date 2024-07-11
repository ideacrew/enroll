Feature: Email Address Feature
    Background: Setup permissions and other things
        Given bs4_consumer_flow feature is disable
        Given all permissions are present

    Scenario: user is on hbx home page and email address feature is enabled
        Given EnrollRegistry contact_email_header_footer_feature feature is enabled
        When the user visits the HBX home page
        Then they should see the contact email address

      Scenario: user is on hbx home page and email address feature is disabled
        Given EnrollRegistry contact_email_header_footer_feature feature is disabled
        When the user visits the HBX home page
        Then they should not see the contact email address

      Scenario: user is signed in and email address feature is enabled
        Given EnrollRegistry contact_email_header_footer_feature feature is enabled
        And that a user with a HBX staff role with HBX staff subrole exists and is logged in
        When user visits the HBX Portal
        Then they should see the contact email address

      Scenario: user is signed in and email address_feature feature is disabled
        Given EnrollRegistry contact_email_header_footer_feature feature is disabled
        And that a user with a HBX staff role with HBX staff subrole exists and is logged in
        When user visits the HBX Portal
        Then they should not see the contact email address
        