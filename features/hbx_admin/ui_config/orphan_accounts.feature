Feature: Orphan Accounts tab
    Background: Setup permissions and other things
        Given all permissions are present

    Scenario: hbx admin logged in and orphan accounts tab is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And orphan accounts feature is enabled
        And user visits the HBX Portal
        When the user clicks the Admin tab
        Then they should see the Orphan Accounts tab

    Scenario: hbx admin logged in and orphan accounts tab is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And orphan accounts feature is disabled
        And user visits the HBX Portal
        When the user clicks the Admin tab
        Then they should not see the Orphan Accounts tab

    Scenario: orphan accounts Tab is disabled with External Routing
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And orphan accounts feature is disabled
        When the user types in the orphan accounts URL
        Then the user will not be able to access orphan accounts page

    Scenario: orphan accounts Tab is enabled with External Routing
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And orphan accounts feature is enabled
        When the user types in the orphan accounts URL
        Then the user will be able to access orphan accounts page

    Scenario: hbx_read_only logged in and orphan accounts tab is enabled
        Given that a user with a HBX staff role with hbx_read_only subrole exists and is logged in
        And orphan accounts feature is enabled
        And user visits the HBX Portal
        When the user clicks the Admin tab
        Then the user clicks on Orphan User Accounts
        Then access will be denied for the user

    Scenario: hbx_read_only logged in and orphan accounts Tab is enabled with External Routing
        Given that a user with a HBX staff role with hbx_read_only subrole exists and is logged in
        And orphan accounts feature is enabled
        When the user types in the orphan accounts URL
        Then access will be denied for the user
