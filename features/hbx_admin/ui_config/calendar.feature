Feature: Calendar tab
    Background: Setup permissions and other things
        Given all permissions are present

    Scenario: hbx admin logged in and calendar tab is enabled
        Given calendar feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Admin tab
        Then they should see the Calendar tab

    Scenario: hbx admin logged in and calendar tab is disabled
        Given calendar feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Admin tab
        Then they should not see the Calendar tab

    Scenario: Calendar Tab is disabled with External Routing
        Given calendar feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        When the user types in the calendar URL
        Then the user will not be able to access calendar page

    Scenario: Calendar Tab is enabled with External Routing
        Given calendar feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        When the user types in the calendar URL
        Then the user will be able to access calendar page