Feature: Orphan Accounts tab
    Background: Setup permissions and other things
        Given all permissions are present

    Scenario: hbx admin logged in and orphan accounts tab is enabled
        Given orphan accounts feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Admin tab
        Then they should see the Orphan Accounts tab

    Scenario: hbx admin logged in and orphan accounts tab is disabled
        Given orphan accounts feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Admin tab
        Then they should not see the Orphan Accounts tab