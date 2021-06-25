Feature: Admin has ability to create a new SEP Type
  Background:
    Given both shop and fehb market configurations are enabled
    Given all market kinds are enabled for user to select
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  Scenario Outline: Admin will create a new <market_kind> SEP type
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin creates new SEP Type with <market_kind> market and <action> select termination on kinds with success scenario
    Then Admin should see SEP Type Created Successfully message
    And Admin should see newly created SEP Type title on Datatable with Draft filter <market_kind>

    Examples:
      | market_kind | action |
      | individual  | cannot |
      | shop        | can    |
      | fehb        | can    |

  Scenario Outline: Failure scenario to create <market_kind> market SEP type
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin creates new SEP Type with <market_kind> market and <action> select termination on kinds with failure scenario
    Then Admin should see failure for end date

    Examples:
      | market_kind | action |
      | individual  | cannot |
      | shop        | can    |
      | fehb        | can    |


  Scenario Outline: Admin will create a new <market_kind> SEP type with/without selecting termination on kinds
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin creates new SEP Type with <market_kind> market and <action> select termination on kinds with success scenario
    Then Admin should see SEP Type Created Successfully message
    And Admin should see newly created SEP Type title on Datatable with Draft filter <market_kind>

    Examples:
      | market_kind | action       |
      | shop        | selected     |
      | fehb        | selected     |
      | shop        | not selected |
      | fehb        | not selected |

  Scenario Outline: Admin should see failure when creating SEP type with <failure_type>
    Given Admin can navigate to the Manage SEPs screen
    When Admin creates new SEP Type with individual market and cannot select termination on kinds with <failure_type> scenario
    Then Admin should see failure for <failure_msg>
    And Hbx Admin logs out

    Examples:
    | failure_type                | failure_msg              |
    | past start date             | start date               |
    | invalid eligibity date      | invalid eligibility date |
    | only eligibility start date | eligibility end date     |
    | only eligibility end date   | eligibility start date   |
