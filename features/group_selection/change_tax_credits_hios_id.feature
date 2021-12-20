Feature: Change Tax Credit button

  Background:
    Given enable change tax credit button is enabled
    Given a consumer exists
    Given the FAA feature configuration is enabled
    Given the automatic application of aptc on enrollment feature configuration is disabled
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a health enrollment with primary person covered
    And the family has an active tax household
    And consumer has successful ridp
    When consumer visits home page

  Scenario Outline: Change Tax Credit button is available for all HIOS ID endings
    Given the enrollment has HIOS ID ending in <id_number>
    And the metal level is gold
    And the tax household has at least one member that is APTC eligible
    When consumer should be able to see Actions dropdown
    Then consumer clicks on the Actions button
    When consumer clicks on the make changes to my coverage button
    Then the Change Tax Credit button should be available

    Examples:
      | id_number |
      | "01"      |
      | "02"      |
      | "03"      |
      | "04"      |
      | "05"      |
      | "06"      |