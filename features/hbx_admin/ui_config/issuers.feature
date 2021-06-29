Feature: Issuers tab
    Background: Setup permissions and other things
        Given all permissions are present

    Scenario: hbx admin logged in and issuers tab is enabled
        Given issuers feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        Then they should see the Issuers tab

    Scenario: hbx admin logged in and issuers tab is disabled
        Given issuers feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        Then they should not see the Issuers tab
    



