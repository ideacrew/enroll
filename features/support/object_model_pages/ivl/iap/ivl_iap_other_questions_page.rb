# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/applicants/consumer_role_id/other_questions
class IvlIapOtherQuestions

  def self.is_pregnant_no_radiobtn
    'is_pregnant_no'
  end
  
  def self.is_post_partum_period_no_radiobtn
    'is_post_partum_period_no'
  end

  def self.is_pregnant_yes_radiobtn
    'input[id="is_pregnant_yes"]'
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
    'div[class="selectric interaction-choice-control-children-expected-count interaction-choice-control-foster-care-us-state interaction-choice-control-age-left-foster-care interaction-choice-control-student-kind interaction-choice-control-student-school-kind"]'
  end

  def self.select_one
    'li[class="interaction-choice-control-children-expected-count-1 interaction-choice-control-foster-care-us-state-1 interaction-choice-control-age-left-foster-care-1 interaction-choice-control-student-kind-1 interaction-choice-control-student-school-kind-1"]'
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

  def self.person_blind_no_radiobtn
    'is_self_attested_blind_no'
  end

  def self.person_blind_yes_radiobtn
    'input[id="is_self_attested_blind_yes"]'
  end

  def self.not_sure_blind_link
    'a[href="#is_self_assisted_blind"]'
  end

  def self.has_daily_living_help_no_radiobtn
    'has_daily_living_no'
  end

  def self.has_daily_living_help_yes_radiobtn
    'input[id="has_daily_living_help_yes"]'
  end

  def self.not_sure_has_daily_living_help
    'a[href="#has_daily_living_help"]'
  end

  def self.need_help_paying_bills_no_radiobtn
    'need_help_paying_bills_no'
  end

  def self.need_help_paying_bills_yes_radiobtn
    'input[id="need_help_paying_bills_yes"]'
  end

  def self.not_sure_need_help_paying_bills_link
    'a[href="#need_help_paying_bills"]'
  end

  def self.physically_disabled_no_radiobtn
    'radio_physically_disabled_no'
  end

  def self.physically_disabled_yes_radiobtn
    'input[id="radio_physically_disabled_yes"]'
  end
  
  def self.not_sure_physically_disabled_link
    'a[data-target="#is_physically_disabled"]'
  end

  def self.continue_btn
    'input[class="btn btn-lg btn-primary btn-block interaction-click-control-continue"]'
  end

  def self.save_and_exit
    'a[class="interaction-click-control-save---exit"]'
  end

  def self.previous
    'a[class="interaction-click-control-previous"]'
  end
end