# frozen_string_literal: true

# Applicant form
module FinancialAssistance
  # For financial assistance applicants
  class ApplicantForm

    def self.applicant_first_name
      'applicant[first_name]'
    end

    def self.applicant_last_name
      'applicant[last_name]'
    end

    def self.applicant_form_dob
      'jq_datepicker_ignore_applicant[dob]'
    end

    def self.applicant_form_ssn
      'applicant[ssn]'
    end

    def self.applicant_spouse_select
      "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Spouse')]"
    end

    def self.applicant_form_gender_select_male
      '//label[@for="radio_male"]'
    end

    def self.is_applying_coverage_true
      '//label[@for="is_applying_coverage_true"]'
    end

    def self.radio_incarcerated_no
      'radio_incarcerated_no'
    end

    def self.indian_tribe_no
      'indian_tribe_member_no'
    end

    def self.us_citizen_true
      'applicant_us_citizen_true'
    end

    def self.naturalized_citizen_false
      'applicant_naturalized_citizen_false'
    end
  end
end