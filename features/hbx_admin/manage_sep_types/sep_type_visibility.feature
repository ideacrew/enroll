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
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  Scenario Outline: Admin will create a new Individual market SEP type by picking visibility option for <user_visibility>
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of individual market is present
    When Admin creates new SEP Type with individual market and see select termination on kinds with <user_visibility> scenario
    And Admin should see newly created SEP Type title on Datatable with Draft filter individual
    And Admin should publish newly created SEP Type
    And Hbx Admin logs out
    And Individual has not signed up as an HBX user
    And Patrick Doe has a consumer role and IVL enrollment
    And Patrick Doe has active individual market role and verified identity
    And Patrick Doe logged into the consumer portal
    And I should see listed individual market SEP Types
    And I should <action> the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    And I click on log out link
    And Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    And Admin clicks Families tab
    And the Admin is navigated to the Families screen
    And I click the name of Patrick Doe from family list
    Then I should see listed individual market SEP Types
    And I should see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    And Admin logs out

    Examples:
      | user_visibility  | action  |
      | Customer & Admin | see     |
      | Admin Only       | not see |

  Scenario Outline: Admin will create a new Individual market SEP type by picking visibility option for <user_visibility> with future date
    Given Admin can navigate to the Manage SEPs screen
    When Admin creates new SEP Type with individual market and cannot select termination on kinds with future start and end dates scenario
    And Admin navigates to SEP Types List page
    And Admin clicks individual filter on SEP Types datatable
    And Admin clicks on Draft filter of individual market filter
    And Admin clicks on newly created SEP Type
    And Admin should navigate to update SEP Type page
    And Admin clicks on Publish button
    And Admin should see Successfully publish message
    And Patrick Doe has a consumer role and IVL enrollment
    And Patrick Doe has active individual market role and verified identity
    And user Patrick Doe logs into the portal
    And I should see listed individual market SEP Types
    And I should not see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    And I click on log out link
    And Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    And Admin clicks Families tab
    And the Admin is navigated to the Families screen
    And Admin clicks name of a ivl family person on the family datatable
    Then I should see listed individual market SEP Types
    And I should not see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    And Admin logs out

    Examples:
      | user_visibility  |
      | Customer & Admin |
      | Admin Only       |

  Scenario Outline: Admin will create a new Shop market SEP type by picking visibility option for <user_visibility>
    Given the shop market configuration is enabled
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of shop market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects shop market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin can select termination on kinds for shop SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin selects <user_visibility> visibility radio button for shop market
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks shop filter on SEP Types datatable
    And Admin clicks on Draft filter of shop market filter
    Then Admin should see newly created SEP Type title on Datatable
    When Admin clicks on newly created SEP Type
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see Successfully publish message
    And Hbx Admin logs out
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has active benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And employee Patrick Doe has past hired on date
    Given Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    Then I should <action> the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    And Employee logs out
    When Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    When Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And Admin clicks name of a shop family person on the family datatable
    Then I should land on home page
    And I should see listed shop market SEP Types
    And I should see the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    And Admin logs out

    Examples:
      | user_visibility  | action  |
      | Customer & Admin | see     |
      | Admin Only       | not see |

  Scenario Outline: Admin will create a new Shop market SEP type by picking visibility option for <user_visibility> with future date
    Given the shop market configuration is enabled
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of shop market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with future start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects shop market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin can select termination on kinds for shop SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin selects <user_visibility> visibility radio button for shop market
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks shop filter on SEP Types datatable
    And Admin clicks on Draft filter of shop market filter
    Then Admin should see newly created SEP Type title on Datatable
    When Admin clicks on newly created SEP Type
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see Successfully publish message
    And Hbx Admin logs out
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has active benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And employee Patrick Doe has past hired on date
    Given Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    Then I should not see the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    And Employee logs out
    When Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    When Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And Admin clicks name of a shop family person on the family datatable
    Then I should land on home page
    And I should see listed shop market SEP Types
    And I should not see the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    And Admin logs out

    Examples:
      | user_visibility  |
      | Customer & Admin |
      | Admin Only       |
