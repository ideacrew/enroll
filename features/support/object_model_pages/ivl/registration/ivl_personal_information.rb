# frozen_string_literal: true

#insured/consumer_role/search
#insured/consumer_role/match
class IvlPersonalInformation

  def self.application_type_dropdown
    '.col-lg-8.col-md-8 span'
  end

  def self.phone_btn
    'div.selectric-open li[data-index="1"]'
  end

  def self.first_name
    'FIRST NAME *'
  end

  def self.middle_name
    'MIDDLE NAME'
  end

  def self.last_name
    'LAST NAME *'
  end

  def self.suffix_dropdown
    'div.selectric-labeled span.label'
  end

  def self.sr_option
    'div.selectric-open li[data-index="2"]'
  end

  def self.need_coverage_yes
    'div.col-xs-2 span.yes_no_pair'
  end

  def self.need_coverage_no
    'label[for="is_applying_coverage_false"] span.yes_no_pair'
  end

  def self.dob
    'jq_datepicker_ignore_person[dob]'
  end

  def self.ssn
    'person[ssn]'
  end

  def self.i_dont_have_an_ssn_checkbox
    '.interaction-choice-control-value-person-no-ssn'
  end

  def self.male_radiobtn
    'label[for="radio_male"] span'
  end

  def self.female_radiobtn
    'label[for="radio_female"] span'
  end

  def self.continue_btn
    'span.no-op span.btn-lg, a.interaction-click-control-continue'
  end

  def self.select_continue_message
    'Next, we need to verify if you or you and your family are eligible to enroll in coverage through DC Health Link. Select CONTINUE.'
  end

  def self.previous_link
    '.interaction-click-control-previous'
  end

  def self.tobacco_user_yes_radiobtn
    'label[for="person_is_tobacco_user_y"] span'
  end

  def self.tobacco_user_no_radiobtn
    'label[for="person_is_tobacco_user_n"] span'
  end

  def self.us_citizen_or_national_yes_radiobtn
    'label[for="person_us_citizen_true"] span'
  end

  def self.us_citizen_or_national_no_radiobtn
    'label[for="person_us_citizen_false"] span'
  end

  def self.naturalized_citizen_yes_radiobtn
    'label[for="person_naturalized_citizen_true"] span'
  end

  def self.naturalized_citizen_no_radiobtn
    'label[for="person_naturalized_citizen_false"] span'
  end

  def self.naturalized_citizen_select_doc_dropdown
    'div#naturalization_doc_type_select span.label'
  end

  def self.immigration_status_yes_radiobtn
    'label[for="person_eligible_immigration_status_true"] span'
  end

  def self.immigration_status_no_radiobtn
    'label[for="person_eligible_immigration_status_false"] span'
  end

  def self.immigration_status_checkbox
    '#person_eligible_immigration_status'
  end

  def self.immigration_status_select_doc_dropdown
    'div#immigration_doc_type_select span'
  end

  def self.select_permanent_resident_card
    'div[id="immigration_doc_type_select"] li[data-index="2"]'
  end

  def self.alien_number
    'person[consumer_role][vlp_documents_attributes][0][alien_number]'
  end

  def self.card_number
    'person[consumer_role][vlp_documents_attributes][0][card_number]'
  end

  def self.expiration_date
    'person[consumer_role][vlp_documents_attributes][0][expiration_date]'
  end

  def self.american_or_alaskan_native_yes_radiobtn
    'label[for="indian_tribe_member_yes"] span'
  end

  def self.american_or_alaskan_native_no_radiobtn
    'label[for="indian_tribe_member_no"] span'
  end

  def self.tribe_state_dropdown
    '#tribal-state-container .selectric span.label'
  end

  def self.tribal_id
    'person[tribal_id]'
  end

  def self.tribal_name
    'tribal-name'
  end

  def self.incarcerated_yes_radiobtn
    'label[for="radio_incarcerated_yes"] span'
  end

  def self.incarcerated_no_radiobtn
    'label[for="radio_incarcerated_no"] span'
  end

  def self.white_checkbox
    '#person_ethnicity_white'
  end

  def self.black_or_african_american_checkbox
    '#person_ethnicity_black_or_african_american'
  end

  def self.asian_indian_checkbox
    '#person_ethnicity_asian_indian'
  end

  def self.chinese_checkbox
    '#person_ethnicity_chinese'
  end

  def self.filipino_checkbox
    '#person_ethnicity_filipino'
  end

  def self.japanese_checkbox
    '#person_ethnicity_japanese'
  end

  def self.korean_checkbox
    '#person_ethnicity_korean'
  end

  def self.vietnamese_checkbox
    '#person_ethnicity_vietnamese'
  end

  def self.other_asian_checkbox
    '#person_ethnicity_other_asian'
  end

  def self.native_hawaiian_checkbox
    '#person_ethnicity_native_hawaiian'
  end

  def self.samoan_checkbox
    '#person_ethnicity_samoan'
  end

  def self.guamanian_or_chamorro_checkbox
    '#person_ethnicity_guamanian_or_chamorro'
  end

  def self.other_pacific_islander_checkbox
    '#person_ethnicity_other_pacific_islander'
  end

  def self.american_indian_checkbox
    '#person_ethnicity_american_indianalaska_native'
  end

  def self.other_race_checkbox
    'div.col-md-3.col-xs-6 input#person_ethnicity_other'
  end

  def self.mexican_checkbox
    '#person_ethnicity_mexican'
  end

  def self.mexican_american_checkbox
    '#person_ethnicity_mexican_american'
  end

  def self.chicano_or_chicanoa_checkbox
    '#person_ethnicity_chicanoa'
  end

  def self.puerto_rican_checkbox
    '#person_ethnicity_puerto_rican'
  end

  def self.cuban_checkbox
    '#person_ethnicity_cuban'
  end

  def self.hispanic_or_latino_other_checkbox
    'div.col-md-4.col-xs-6 input#person_ethnicity_other'
  end

  def self.address_line_one
    'person[addresses_attributes][0][address_1]'
  end

  def self.address_line_two
    'person[addresses_attributes][0][address_2]'
  end

  def self.city
    'person[addresses_attributes][0][city]'
  end

  def self.select_state_dropdown
    'div.home-div span.label'
  end

  def self.select_dc_state
    'div.selectric-address_required li[data-index="10"]'
  end

  def self.zip
    'person[addresses_attributes][0][zip]'
  end

  def self.living_outside_dc_checkbox
    '#person_is_temporarily_out_of_state'
  end

  def self.homeless_dc_resident_checkbox
    '#person_is_homeless'
  end

  def self.add_mailing_address_btn
    '.form-action'
  end

  def self.mailing_address_line_one
    'person[addresses_attributes][1][address_1]'
  end

  def self.mailing_address_line_two
    'person[addresses_attributes][1][address_2]'
  end

  def self.mailing_address_city
    'person[addresses_attributes][1][city]'
  end

  def self.mailing_address_state_dropdown
    'div.mailing-div span.label'
  end

  def self.mailing_address_zip
    'person[addresses_attributes][1][zip]'
  end

  def self.remove_mailing_address_btn
    '.form-action'
  end

  def self.home_phone
    'person[phones_attributes][0][full_phone_number]'
  end

  def self.mobile_phone
    'person[phones_attributes][1][full_phone_number]'
  end

  def self.personal_email_address
    'person[emails_attributes][0][address]'
  end

  def self.work_email_address
    'person[emails_attributes][1][address]'
  end

  def self.language_preference_dropdown
    'div.selectric-below span.label'
  end

  def self.help_me_sign_up_btn
    '.help-me-sign-up'
  end

  def self.save_and_exit_link
    '.interaction-click-control-save---exit'
  end

  def self.personal_save
    '[data-cuke="personal-save"]'
  end
end
