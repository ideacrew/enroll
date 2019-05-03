Scenario: HBX Admin uses search filter dropdowns on Families Index Page

  Background: Create HBX Admin
    Given an HBX admin is present

  Scenario Outline: HBX Admin Searches by Market Type
    Given a family with SHOP HBX Enrollment is present
    And a family with IVL HBX Enrollment is present
    And a family with COBRA HBX Enrollment is present
    And HBX admin visits the families index page
    When HBX admin selects <market type search query> market type from the search dropdown
    And HBX admin clicks submit button
    Then HBX admin should only see <market type search query> families in the results
    And HBX admin should not see <other market types> in the results

    Examples:
    | market type search query  | other market types |
    |  All Market Types         |					 |
    |  SHOP						| IVL COBRA			 |
    |  IVL						| SHOP COBRA		 |
    |  COBRA					| IVL SHOP			 |

  Scenario Outline: HBX Admin Searches by Coverage Type
    Given a family with Medical HBX Enrollment is present
    And a family with Dental HBX Enrollment is present
    And HBX admin visits the families index page
    When HBX admin selects <coverage type search query> market type from the search dropdown
    And HBX admin clicks submit button
    Then HBX admin should only see <coverage type search query> families in the results
    And HBX admin should not see <other coverage types> in the results

    Examples:
    | coverage type search query  | other coverage types |
    |  All Coverage Types         |					     |
    |  Medical					  |  Dental			     |
    |  Dental					  |  Medical			 |

  
  # The plan year search queries have not been implemented, 
  # But perhaps only one or two examples is needed if the query they use
  # is reused by year
  Scenario Outline: HBX Admin Searches by Plan Year
    Given a families with plan years for 2016, 2017, 2018, and 2019 are present
    And HBX admin visits the families index page
    When HBX admin selects <plan year search query> plan year from the search dropdown
    And HBX admin clicks submit button
    Then HBX admin should only see <plan year search query> families in the results
    And HBX admin should not see <other plan yearsr> in the results

    Examples:
    | plan year search query  | other plan years |
    |  All Plan Years         |					 |
    |  2016					  |  2017 2018 2019	 |

  # Terminated is currently on the dropdown for this too, was just there for testing
  # probably will be removed before implementing, double check with BA's for requirements
  Scenario Outline: HBX Admin Searches by Active HBX Enrollment Status
    Given a family with active HBX Enrollment is present
    And a family with inactive HBX Enrollment is present
    And HBX admin visits the families index page
    When HBX admin selects <active status search query> coverage type families from the search dropdown
    And HBX admin clicks submit button
    Then HBX admin should only see <active status search query> families in the results
    And HBX admin should not see <other active statuses> in the results

    Examples:
    | active status search query  | other active statuses |
    |  All Active/Inactive        |					      |
    |  active					  |  inactive             |
    |  inactive                   |  active               |

