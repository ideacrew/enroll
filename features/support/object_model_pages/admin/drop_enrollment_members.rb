# frozen_string_literal: true

#admin/families tab/ drop enrollment members action
class DropEnrollmentMembers

  def self.drop_enrollment_members_button
    '[data-cuke="drop_enrollment_members_button"]'
  end

  def self.drop_enrollment_members_termination_date
    '[data-cuke="drop_termination_date"]'
  end

  def self.drop_enrollment_members_transmit_checkbox
    '[data-cuke="transmit_drop_members"]'
  end

  def self.drop_enrollment_members_submit
    '[data-cuke="drop_members_submit"]'
  end

  def self.none_selected
    '[data-cuke="no_drop_members_selected"]'
  end

  def self.failed_to_drop_members
    '[data-cuke="failed_to_drop_members"]'
  end

  def self.dropped_members_success
    '[data-cuke="dropped_members_success"]'
  end

  def self.drop_enrollment_members_title
    '[data-cuke="drop_enrollment_members_title"]'
  end

  def self.drop_member_select_checkbox
    '[data-cuke="drop_member_select_checkbox"]'
  end

end
