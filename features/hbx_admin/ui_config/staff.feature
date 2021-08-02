Feature: Staff tab
    Background: Setup permissions and other things
        Given all permissions are present

    Scenario: hbx admin logged in and staff tab is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And staff feature is enabled
        And user visits the HBX Portal
        When the user clicks the Admin tab
        Then they should see the Staff tab

    Scenario: hbx admin logged in and staff tab is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And staff feature is disabled
        And user visits the HBX Portal
        When the user clicks the Admin tab
        Then they should not see the Staff tab
      
    Scenario: Staff Tab is disabled with External Routing
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And staff feature is disabled
        When the user types in the staff index URL
        Then the user will not be able to access staff index page

    Scenario: Staff Tab is enabled with External Routing
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And staff feature is enabled
        When the user types in the staff index URL
        Then the user will be able to access staff index page
