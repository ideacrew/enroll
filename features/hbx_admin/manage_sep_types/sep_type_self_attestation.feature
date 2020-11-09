Feature: Admin has ability to create a new SEP Type with self attestation options for "Customer & Admin" and "Admin Only"
  Background:
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And the FAA feature configuration is enabled
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  @flaky
  Scenario Outline: Admin will create a new Individual market SEP type by picking self attestation option for <user_attestation>
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of individual market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects individual market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin cannot select termination on kinds for individual SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin selects <user_attestation> self attestation radio button for individual market
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks individual filter on SEP Types datatable
    And Admin clicks on Draft filter of individual market filter
    Then Admin should see newly created SEP Type title on Datatable
    When Admin clicks on newly created SEP Type
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see Successfully publish message
    And Hbx Admin logs out
    Given Individual has not signed up as an HBX user
    When Individual with known qles visits the Insured portal outside of open enrollment
    Then Individual creates a new HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual does not apply for assistance and clicks continue
    Then Individual should see the dependents form
    And I click on continue button on household info form
    When I click on none of the situations listed above apply checkbox
    And I click on back to my account button
    Then I should land on home page
    And I should see listed individual market SEP Types
    And I should see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    When I click on the "Entered into a legal domestic partnership" Sep Type
    Then I should <action> input field to enter the Sep Type date
    And I click on log out link
    When Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    When Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And Admin clicks name of a ivl family person on the family datatable
    Then I should land on home page
    And I should see listed individual market SEP Types
    And I should see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    When I click on the "Entered into a legal domestic partnership" Sep Type
    Then I should <action> input field to enter the Sep Type date
    And Admin logs out

    Examples:
      | user_attestation | action  |
      | Self Service     | see     |
      | Admin Only       | not see |

  Scenario Outline: Admin will create a new Shop market SEP type by picking self attestation option for <user_attestation>
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
    And Admin selects <user_attestation> self attestation radio button for shop market
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
    Then Employee should see the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    When Employee click on the "Entered into a legal domestic partnership" Sep Type
    Then Employee should <action> input field to enter the Sep Type date
    And Employee logs out
    When Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    When Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And Admin clicks name of a shop family person on the family datatable
    Then I should land on home page
    And I should see listed shop market SEP Types
    And Admin should see the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    When Admin click on the "Entered into a legal domestic partnership" Sep Type
    Then Admin should <action> input field to enter the Sep Type date
    And Admin logs out

    Examples:
      | user_attestation | action  |
      | Self Service     | see     |
      | Admin Only       | not see |
