require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeSepDetails < MongoidMigrationTask
  def migrate
    sep = SpecialEnrollmentPeriod.find(ENV["sep_id"])
    action = ENV["action"]

    case action
    when "change_market_kind"
      change_market_kind(sep)
    else
    end
  end

  def change_market_kind(sep)
    valid_sep_enrollments = sep.family.active_household.hbx_enrollments.show_enrollments_sans_canceled.special_enrollments
    qle_market_kind = sep.qualifying_life_event_kind.market_kind

    if valid_sep_enrollments.map(&:special_enrollment_period_id).include?(sep.id)
      return "This SEP has an Enrollment. Get business confirmation & handle enrollment"
    elsif sep.qualifying_life_event_kind.market_kind == sep.market_kind
      return "QLE & SEP has same market_kind. Why do you want to change the market kind?"
    else
      sep.update_attributes!(market_kind: qle_market_kind)
      puts "Succesfully updated SEP market_kind to #{sep.market_kind}" unless Rails.env.test?
    end
  end
end
