Feature: ACA Individual Market Link 
    Background: Setup permissions and other things
        Given all permissions are present
        And Patrick Doe has active individual market role and verified identity

    Scenario: individual market link is enabled and hbx admin visits Resident Application Link
        Given no transition families feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Families tab
        Then they should see the Resident Application Link

    Scenario: individual market link is disabled and hbx admin visits Resident Application Link
        Given no transition families feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Families tab
        Then they should not see the Resident Application Link

    Scenario: individual market link is enabled and hbx admin visits Transition Family Members Link
        Given no transition families feature is enabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Families tab
        And the user clicks the Families link
        Given the user clicks the Actions tab
        Then they should see the Transition Family Members Link

    Scenario: individual market link is disabled and hbx admin visits Resident Application Link
        Given no transition families feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        Given user visits the HBX Portal
        And the user clicks the Families tab
        And the user clicks the Families link
        Given the user clicks the Actions tab
        Then they should not see the Transition Family Members Link

    Scenario: Disable /exchanges/residents/search URL
        Given no transition families feature is disabled
        Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
        And the user navigates to the resident applications url
        Then they should be redirected to the welcome page


