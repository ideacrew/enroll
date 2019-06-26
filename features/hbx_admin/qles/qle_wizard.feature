Feature: As an HBX Admin User I can access the QLE management wizard

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    Given benefit market catalog exists for ABC Widgets initial employer with health benefits
    And employer ABC Widgets has enrollment_open benefit application 


  Scenario Outline: HBX Staff with Super Admin subroles can access and manage the QLE Wizard page
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Main Page
    And the user goes to the Config Page
    Then the user will not see the Time Tavel option
