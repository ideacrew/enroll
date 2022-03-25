Feature: Display Enrollment Summary
  Both users and admins are able to see this page

  Background:
    Given a consumer exists
    Given the display enrollment summary configuration is enabled
    And the consumer is logged in
    And consumer also has a health enrollment with primary person covered
    And the family has an active tax household
    And consumer has successful ridp
    When consumer visits home page

  Scenario: User views the Enrollment Summary page
    Given the enrollment is a Health plan
    When consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    When consumer clicks on the View my coverage details
    Then additional Enrollment Summary exists
