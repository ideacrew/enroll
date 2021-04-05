Feature: Admin has ability to update a Draft SEP Type
  Background:
    Given both shop and fehb market configurations are enabled
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  Scenario Outline: Admin will create a new <market_kind> SEP type and publish it
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Draft filter of <market_kind> market filter
    Then Admin should see newly created SEP Type title on Datatable
    When Admin clicks on newly created SEP Type
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see Successfully publish message
    And Hbx Admin logs out

    Examples:
      | market_kind | action |
      | individual  | cannot |
      | shop        | can    |
      | fehb        | can    |

  Scenario Outline: Admin should able to Create and Publish new SEP Type with Active SEP Type reason
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin fills active reason for <market_kind> SEP type form
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Draft filter of <market_kind> market filter
    Then Admin should see newly created SEP Type title on Datatable
    When Admin clicks on newly created SEP Type
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see Successfully publish message
    And Hbx Admin logs out

    Examples:
      | market_kind | action |
      | individual  | cannot |
      | shop        | can    |
      | fehb        | can    |


  Scenario Outline: Failure scenario to Publish a newly created <market_kind> market SEP type
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills active title for <market_kind> SEP type form
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin fills active reason for <market_kind> SEP type form
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Draft filter of <market_kind> market filter
    Then Admin should see newly created SEP Type with Active SEP Type title for <market_kind> on Datatable
    When Admin clicks on newly created SEP Type for <market_kind>
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see failure title while publishing a new SEP Type
    And Hbx Admin logs out

    Examples:
      | market_kind | action |
      | individual  | cannot |
      | shop        | can    |
      | fehb        | can    |
