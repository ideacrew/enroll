Feature: Notices tab
    Background: Setup permissions and other things
        Given all permissions are present

    Scenario: hbx admin logged in and notices tab is enabled
        Given notices feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        Then they should see the Notices tab

    Scenario: hbx admin logged in and notices tab is disabled
        Given notices feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        Then they should not see the Notices tab
    
    Scenario: Notices Tab is disabled with External Routing
      Given notices feature is disabled
      Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
      When the user visits the notices page
      Then the user will not be able to access the notices page
