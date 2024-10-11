Feature: Enrollment Tiles

  Background:
    Given bs4_consumer_flow feature is disable
    Given the display enrollment summary configuration is enabled
    Given a Hbx admin with hbx_staff role exists
    Given a consumer exists
    And consumer also has a dental enrollment with primary person covered
    And consumer also has a health enrollment with primary person covered
    And the family has an active tax household
    And consumer has successful ridp

  Scenario: Refactored tiles appear when feature is turned on
    And the enrollment is a Health plan
    Given EnrollRegistry enrollment_plan_tile_update feature is enabled
    And the consumer is logged in
    When consumer visits home page
    Then consumer should be able to see the new enrollment tile styling

  Scenario: Dental plans should appear below health plans
    Given EnrollRegistry enrollment_plan_tile_update feature is enabled
    And the consumer is logged in
    When consumer visits home page
    Then consumer should see the dental plan below the health plan
