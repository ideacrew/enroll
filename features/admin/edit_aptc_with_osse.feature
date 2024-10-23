Feature: APTC cannot be below 85% for OSSE plan

  Background:
    Given a consumer exists
    And consumer also has a health enrollment with primary person covered
    And the family has an active tax household
    And consumer has successful ridp
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    When Hbx Admin click Families link
    And Hbx Admin clicks Actions button

  Scenario: APTC slider should be minimum 85% when enrollment is OSSE eligible
    Given self service osse feature is enabled
    Given active enrollment is OSSE eligible with APTC
    Given Tax household member info exists for user
    And Hbx Admin clicks the Edit APTC CSR link
    Then APTC slider should show minimum 85%
    When Hbx Admin enters an APTC amount below 85%
    Then Hbx Admin should see the OSSE APTC error message
