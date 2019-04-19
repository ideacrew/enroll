Feature: Employer Profile
  In order for initial employers to submit application
  Employer Staff should upload attestation document
  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    And it has an employer ABC Widgets with no attestation submitted
    And ABC Widgets employer has a staff role
    And employer ABC Widgets has draft benefit application
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information

  Scenario: Initial employer tries to submit application without uploading attestation
    When Employer clicks on publish plan year
    # TODO This doesn't work this way anymore?
    # Then Employer Staff should see dialog with Attestation warning
    # When Employer Staff clicks cancel button in Attestation warning dialog
    # Then Employer Staff should redirect to plan year edit page
