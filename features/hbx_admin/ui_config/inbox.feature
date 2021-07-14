Feature: Inbox tab
    Background: Setup permissions and other things
        Given all permissions are present

    Scenario: hbx admin logged in and inbox tab is enabled
        Given inbox feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        Then they should see the Inbox tab

    Scenario: hbx admin logged in and inbox tab is disabled
        Given inbox feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        Then they should not see the Inbox tab