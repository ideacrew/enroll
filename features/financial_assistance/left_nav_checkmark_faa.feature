Feature: Left Nav Uses Checkmarks

Background: Left Nav
  Given that an FAA application is in the draft state
  And the user is on FAA Household Info: Family Members page
  And the left column will present the following sections Financial Assistance, Household Info & Review & Submit

Scenario: Given the user is an applicant specific page
  When a driver question is answered with NO
  And the user saves the answer
  Then the corresponding section should be WHITE background & GREY text

Scenario: Given the user is an applicant specific page
  When a driver question is answered with NO
  And the user saves the answer
  Then the corresponding section should be WHITE background & GREY text
  And a check mark will not appear on the left nav for that section

Scenario: Given that a driver question is answered with NO
  When a driver question is answered with NO
  And the user saves the answer
  Then the corresponding section should be WHITE background & GREY text
  And a check mark will not appear on the left nav for that section
  Then the all other sections are confirmed as complete
  And the applicant is complete
