Feature: Admin has ability to create a new SEP Type with visibility options for "Customer & Admin" and "Admin Only"
  Background:
    Given both shop and fehb market configurations are enabled
    And all market kinds are enabled for user to select
    And all announcements are enabled for user to select
    And that a user with a HBX staff role with hbx_tier3 subrole exists
    And Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    And the FAA feature configuration is enabled
    And Qualifying life events of all markets are present

  Scenario Outline: Admin will create a new Individual market SEP type by picking visibility option for <user_visibility>
    Given expired Qualifying life events of individual market is present
    And Admin creates and publishes new SEP Type with individual market and see select termination on kinds with <user_visibility> scenario and current start and end dates
    And Patrick Doe has a consumer role and IVL enrollment
    And Patrick Doe has active individual market role and verified identity
    When user Patrick Doe logs into the portal
    Then I should see listed individual market SEP Types
    And I should <action> the "Entered into a legal domestic partnership" at the bottom of the ivl qle list

    Examples:
      | user_visibility  | action  |
      | Customer & Admin | see     |
      | Admin Only       | not see |

    Scenario Outline: Admin will create a new Individual market SEP type by picking visibility option for <user_visibility>
      Given expired Qualifying life events of individual market is present
      And Admin creates and publishes new SEP Type with individual market and see select termination on kinds with <user_visibility> scenario and current start and end dates
      And Patrick Doe has a consumer role and IVL enrollment
      And Patrick Doe has active individual market role and verified identity
      And Admin clicks Families tab
      And the Admin is navigated to the Families screen
      When I click the name of Patrick Doe from family list
      Then I should see listed individual market SEP Types
      And I should see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list

      Examples:
        | user_visibility  |
        | Customer & Admin |
        | Admin Only       |

  Scenario Outline: Admin will create a new Individual market SEP type by picking visibility option for <user_visibility> with future date
    Given expired Qualifying life events of individual market is present
    And Admin creates and publishes new SEP Type with individual market and see select termination on kinds with <user_visibility> scenario and future start and end dates
    And Patrick Doe has a consumer role and IVL enrollment
    And Patrick Doe has active individual market role and verified identity
    And user Patrick Doe logs into the portal
    And I should see listed individual market SEP Types
    And I should not see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list

    Examples:
      | user_visibility  |
      | Customer & Admin |
      | Admin Only       |

  Scenario Outline: Admin will create a new Individual market SEP type by picking visibility option for <user_visibility> with future date
    Given expired Qualifying life events of individual market is present
    And Admin creates and publishes new SEP Type with individual market and see select termination on kinds with <user_visibility> scenario and future start and end dates
    And Patrick Doe has a consumer role and IVL enrollment
    And Patrick Doe has active individual market role and verified identity
    And Admin clicks Families tab
    And the Admin is navigated to the Families screen
    When I click the name of Patrick Doe from family list
    Then I should see listed individual market SEP Types
    And I should not see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list

    Examples:
      | user_visibility  |
      | Customer & Admin |
      | Admin Only       |

  Scenario Outline: Admin will create a new Shop market SEP type by picking visibility option for <user_visibility>
    Given expired Qualifying life events of shop market is present
    And Admin creates and publishes new SEP Type with shop market and see select termination on kinds with <user_visibility> scenario and <date> start and end dates
    And a CCA site exists with a benefit market
    And benefit market catalog exists for active initial employer with health benefits
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has active benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And employee Patrick Doe has past hired on date
    And Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    Then I should <employee_action> the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    And Employee logs out
    And Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    And Admin clicks Families tab
    And the Admin is navigated to the Families screen
    When Admin clicks name of a shop family person on the family datatable
    And I should see listed shop market SEP Types
    And I should <admin_action> the "Entered into a legal domestic partnership" at the bottom of the shop qle list

    Examples:
      | user_visibility  | employee_action     |  date     | admin_action |
      | Customer & Admin | see                 | current   | see          |
      | Admin Only       | not see             | current   | see          |
      | Customer & Admin | not see             | future    | not see      |
      | Admin Only       | not see             | future    | not see      |
