Feature: A dedicated page that gives the user access to household member creation/edit as well as Financial application forms for each household member.

  Background:
    Given the FAA feature configuration is enabled
    When the user is applying for a CONSUMER role
    And the primary member has filled mandatory information required
    And the primary member authorizes system to call EXPERIAN
    And system receives a positive response from the EXPERIAN
    And the user answers all the VERIFY IDENTITY  questions
    And the person named Patrick Doe is RIDP verified
    When the user clicks on submit button
    And the Experian returns a VERIFIED response
    Then the user will navigate to the Help Paying for Coverage page
    And saves a YES answer to the question: Do you want to apply for Medicaid…

  Scenario: new applicant navigation to the FAA Household Info page
    Given that the user is on the Application Checklist page
    When the user clicks CONTINUE
    Then the user will navigate to the FAA Household Infor: Family Members page

  Scenario: Eligible Immigration Status checkbox appears when feature is enabled
    Given eligible immigration status checkbox feature is enabled
    Given that the user is on the Application Checklist page
    When the user clicks CONTINUE
    And consumer clicks on pencil symbol next to primary person
    And consumer chooses no for us citizen
    Then consumer should see the eligible immigration status checkbox
