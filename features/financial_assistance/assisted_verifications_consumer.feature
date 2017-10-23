Feature: After a Financial Assistance Application is Submitted

  Background:
    Given a consumer, with a family, and consumer_role exists
#    And is logged in
#    And a benchmark plan exists
    And that a family has a Financial Assistance application in the submitted state



  Scenario:
    Given that a family has submitted a financial assistance application
    When an eligibility determination is returned to EA from Haven
#    And Haven calls the FED HUB for verification of Income
    And Haven transmits the response to EA
    Then the user will be able to navigate to the Documents page of the account to take actions.

    Given that a family has submitted a financial assistance application
    When an eligibility determination is returned to EA from Haven
#    And Haven calls the FED HUB for verification of Income
    And Haven transmits the an "outstanding" response to EA for any given member
#    And the member is included in a purchased enrollment with past, present or future effective date
    Then Income type will display an "outstanding" verification status

    Given that a family has submitted a financial assistance application
    When an eligibility determination is returned to EA from Haven
#    And Haven calls the FED HUB for verification of Income
    And Haven transmits the an "outstanding" response to EA for any given member
    Then Income type will display an "outstanding" verification status

    Given that a family has submitted a financial assistance application
    When an eligibility determination is returned to EA from Haven
#    And Haven calls the FED HUB for verification of Minimal Essential Coverage (MEC)
    And Haven transmits the response to EA
    Then the user will be able to navigate to the Documents page of the account to take actions.

    Given that a family has submitted a financial assistance application
    When an eligibility determination is returned to EA from Haven
#    And Haven calls the FED HUB for verification of Minimal Essential Coverage (MEC)
    And Haven transmits the an "outstanding" response to EA for any given member
#    And the member is included in a purchased enrollment with past, present or future effective date
    Then MEC type will display an "outstanding" verification status

    Given that a family has submitted a financial assistance application
    When an eligibility determination is returned to EA from Haven
#    And Haven calls the FED HUB for verification of Minimal Essential Coverage (MEC)
    And Haven transmits the an "outstanding" response to EA for any given member
    Then MEC type will display an "outstanding" verification status