Feature: Admin has ability to sort SEP Types on Sort SEPs Page and save their positions in DB
  User will create an account through HBx Portal to sign as Consumer and checks the re arranged positions of SEP Type on Qle carousel
  User will create an account through HBx Portal to sign as Employee and checks the re arranged positions of SEP Type on Qle carousel

  Background:
    Given both shop and fehb market configurations are enabled
    Given all market kinds are enabled for user to select
    Given all announcements are enabled for user to select
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And the FAA feature configuration is enabled
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  Scenario Outline: Admin has ability to sort the SEP Types and saves the positions to the database
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on <market_kind> tab
    Then Admin should see listed <market_kind> market SEP Types with ascending positions
    When Admin sorts <market_type> SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed <market_type> SEP Types ordinal postions should change
    When Admin clicks on List SEP Types link
    Then Admin navigates to SEP Type List page

    Examples:
      | market_kind | market_type |
      | individual  | Individual  |
      | shop        | Shop        |
      | congress    | Congress    |

  Scenario: Admin will sort Individual market SEP Types and it will reflect the same order on the individual insured home page qle carousel
    Given Patrick Doe has a consumer role and IVL enrollment
    And Patrick Doe has active individual market role and verified identity
    And user Patrick Doe logs into the portal
    And I should see the "Had a baby" at the top of the ivl qle list
    And I click on log out link
    And Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link
    And Admin can navigate to the Manage SEPs screen
    And Admin clicks on the Sort SEPs button
    And Admin clicks on individual tab
    When Admin sorts Individual SEP Types by drag and drop
    And listed Individual SEP Types ordinal postions should change
    And Hbx Admin logs out
    And user Patrick Doe logs into the portal
    Then I should see the "Married" at the top of the ivl qle list

  Scenario Outline: Admin will create a new <market_kind> market SEP type with future date and try to sort the Sep Type
    Given Admin creates and publishes new SEP Type with <market_kind> market and see select termination on kinds with <user_visibility> scenario and future start and end dates
    And Admin navigates to SEP Types List page
    And Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Draft filter of <market_kind> market filter
    And Admin clicks on the Sort SEPs button
    When Admin should see three tabs Individual, Shop and Congress markets
    And Admin clicks on <market_kind> tab
    Then Admin should see listed <market_kind> market SEP Types
    And Admin should not see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list

    Examples:
      | market_kind |
      | individual  |
      | shop        |

  Scenario: Admin will sort Shop market SEP Types and it will reflect the same order on the employee home page qle carousel
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has active benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And employee Patrick Doe has past hired on date
    And Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    Then Employee should see the "Covid-19" at the top of the shop qle list
    Then Employee logs out
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And the Admin will see the Manage SEPs under admin dropdown
    When Admin can click Manage SEPs link
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Sort SEPs button
    When Admin sorts Individual SEP Types by drag and drop
    When Admin clicks on shop tab
    When Admin sorts Shop SEP Types by drag and drop
    And Hbx Admin logs out
    When employee visits the Employee Portal page
    And Employee signed in
    And Employee should see the "Married" at the top of the shop qle list

  Scenario Outline: Admin will create a new <market_kind> SEP type and publish it
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    And Admin creates new SEP Type with <market_kind> market and <action> select termination on kinds with success scenario
    And Admin should see SEP Type Created Successfully message
    And Admin should see newly created SEP Type title on Datatable with Draft filter <market_kind>
    And Admin clicks on newly created SEP Type
    And Admin should navigate to update SEP Type page
    And Admin clicks on Publish button
    And Admin should see Successfully publish message
    And Admin clicks on the Sort SEPs button
    And Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on <market_kind> tab
    Then Admin should see listed <market_kind> market SEP Types
    And Admin should see the Entered into a legal domestic partnership in the <market_kind> qle list
    And Hbx Admin logs out

    Examples:
      | market_kind | action |
      | individual  | cannot |
      | shop        | can    |
      | fehb        | can    |
