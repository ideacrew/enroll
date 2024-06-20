# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/applicants/consumer_role_id/other_questions
class IvlIapOtherQuestions

  def self.is_pregnant_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '.interaction-choice-control-value-is-pregnant-no'
    else
    'is_pregnant_no'
    end
  end

  def self.is_post_partum_period_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '.interaction-choice-control-value-is-post-partum-period-no'
    else
    'is_post_partum_period_no'
    end
  end

  def self.is_pregnant_yes_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '.interaction-choice-control-value-is-pregnant-yes'
    else
    'input[id="is_pregnant_yes"]'
    end
  end

  def self.not_sure_pregnant_link
    'a[href="#is_pregnant"]'
  end

  def self.pregnancy_due_date
    'applicant[pregnancy_due_on]'
  end

  def self.calendar
    'table[class="ui-datepicker-calendar"]'
  end

  def self.children_expecting_dropdown
    '.selectric-interaction-choice-control-children-expected-count'
  end

  def self.select_one
    'li[data-index="1"]'
  end

  def self.is_student_no_radiobtn
    'is_student_no'
  end

  def self.is_student_yes_radiobtn
    'input[id="is_student_yes"]'
  end

  def self.student_end_date
    'applicant[student_status_end_on]'
  end

  def self.type_of_student_dropdown
    'div[class="col-md-3"] div[class="selectric"]'
  end

  def self.select_part_time
    'li[data-index="5"]'
  end

  def self.select_full_time
    'li[data-index="2"]'
  end

  def self.type_of_school_dropdown
    'div[class="col-md-3"] div[class="selectric"]'
  end

  def self.select_graduate_school
    'li[data-index="2"]'
  end

  def self.person_blind_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '.interaction-choice-control-value-is-self-attested-blind-no'
    else
    'is_self_attested_blind_no'
    end
  end

  def self.person_blind_yes_radiobtn
    'input[id="is_self_attested_blind_yes"]'
  end

  def self.not_sure_blind_link
    'a[href="#is_self_assisted_blind"]'
  end

  def self.has_daily_living_help_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '.interaction-choice-control-value-has-daily-living-help-no'
    else
    'has_daily_living_no'
    end
  end

  def self.has_daily_living_help_yes_radiobtn
    'input[id="has_daily_living_help_yes"]'
  end

  def self.not_sure_has_daily_living_help
    'a[href="#has_daily_living_help"]'
  end

  def self.need_help_paying_bills_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      '.interaction-choice-control-value-need-help-paying-bills-no'
    else
      'need_help_paying_bills_no'
    end
  end

  def self.need_help_paying_bills_yes_radiobtn
    'input[id="need_help_paying_bills_yes"]'
  end

  def self.not_sure_need_help_paying_bills_link
    'a[href="#need_help_paying_bills"]'
  end

  def self.physically_disabled_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '.interaction-choice-control-value-radio-physically-disabled-no'
    else
    'radio_physically_disabled_no'
    end
  end

  def self.physically_disabled_yes_radiobtn
    'input[id="radio_physically_disabled_yes"]'
  end

  def self.not_sure_physically_disabled_link
    'a[data-target="#is_physically_disabled"]'
  end

  def self.continue_btn
    '.interaction-click-control-continue'
  end

  def self.save_and_exit
    'a[class="interaction-click-control-save---exit"]'
  end

  def self.previous
    'a[class="interaction-click-control-previous"]'
  end

  def self.continue_to_next_step
    '.interaction-click-control-continue-to-next-step'
  end
end