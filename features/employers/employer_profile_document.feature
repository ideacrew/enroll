Feature: Document
  In order for employers to manage their Documents

  Scenario: An Employer should be able to upload document
    Given an employer exists
    And the employer has employees
    And the employer is logged in
    When the employer goes to the documents tab directly
    Then the employer should see upload button
    When the employer clicks upload button
    Then the employer should see model box with file upload
    And the employer fill the document form
    Then the employer clicks the upload button in popup
    Then the employer should see the document list
    And the employer clicks document name
    Then the employer should see Download,Print Option
