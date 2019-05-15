Feature: As a Super Admin I will be the only user
  that is able to see & access the confioguration tab

  Scenario Outline: HBX Staff with <subrole> subroles should <action> the config tab
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Then the user will <action> the Config tab
  
    Examples:
      | subrole       | action |
      | super_admin   |  see   |
      | hbx_tier3     |  see   |
      | hbx_staff     |  see   |
      | hbx_read_only |  see   |

Scenario: HBX Staff with Super Admin subroles should not have the option to time travel
  Given a Hbx admin with read and write permissions exists
  When Hbx Admin logs on to the Hbx Portal
  And the user is on the Main Page
  And the user goes to the Config Page
  Then the user will not see the Time Tavel option

Scenario: HBX Staff with Super Admin subroles and a time travel ability enabled should have the option to time travel
  Given a Hbx admin with read and write permissions exists
  When Hbx Admin logs on to the Hbx Portal
  And the user with a HBX staff role updates permisssions to time travel and super admin
  And the user is on the Main Page
  And the user goes to the Config Page
  Then the user will see the Time Tavel option


