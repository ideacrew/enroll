Feature: Create Eligibility
    In order to create eligibility
    User should have the role of an admin

    Background:
        Given User with tax household exists
        Given Hbx Admin exists
        When Hbx Admin logs on to the Hbx Portal
        When Hbx Admin click Families link
        And Hbx Admin clicks Actions button

    Scenario: Admin views the Create Eligibility tool
        Then Hbx Admin should see a Create Eligibility link

    Scenario: Admin tries to Create Eligibility
        And Hbx Admin clicks on the Create Eligibility button
        Then Hbx Admin should see tax household member level csr select
