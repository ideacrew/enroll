Feature: Staff tab
    Background: Setup permissions and other things
        Given all permissions are present

    Scenario: hbx admin logged in and staff tab is enabled
        Given staff feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Admin tab
        Then they should see the Staff tab

    Scenario: hbx admin logged in and staff tab is disabled
        Given staff feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Admin tab
        Then they should not see the Staff tab