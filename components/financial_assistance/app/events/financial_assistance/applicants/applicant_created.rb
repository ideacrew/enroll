# frozen_string_literal: true
module FinancialAssistance
  module Applicants
    class ApplicantCreated < EventSource::Event
      publisher_key 'financial_assistance.applicants_publisher'
      # attribute_keys :family_id, :family_member_id,:person_hbx_id,:name_pfx,:first_name,:middle_name,:last_name,:name_sfx,
      #    :gender,:is_incarcerated,:is_disabled,:ethnicity,:race,:tribal_id,:language_code,:no_dc_address,:is_homeless,
      #    :is_temporarily_out_of_state,:no_ssn,:citizen_status,:is_consumer_role,:vlp_document_id,:is_applying_coverage,
      #    :vlp_subject,:alien_number,:i94_number,:visa_number,:passport_number,:sevis_id,:naturalization_number,
      #    :receipt_number,:citizenship_number,:card_number,:country_of_citizenship, :issuing_country,:status,
      #    :indian_tribe_member, :same_with_primary,:vlp_description,:dob, :ssn , :relationship, :expiration_date,:addresses,:emails,:phones
    end
  end
end
