# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# rake to add new sep to family
class AddNewSepToFamily < MongoidMigrationTask
  def migrate
    person_hbx_ids = ENV['person_hbx_ids'].split.uniq
    sep_type = ENV['sep_type'].to_s
    qle_reason = ENV['qle_reason'].to_s
    event_date = Date.strptime(ENV['event_date'].to_s, "%m/%d/%Y")
    effective_date = Date.strptime(ENV['effective_date'].to_s, "%m/%d/%Y")
    sep_duration = ENV['sep_duration'].to_i

    person_hbx_ids.each do |hbx_id|
      person = Person.where(hbx_id: hbx_id.to_s).first

      unless person.present?
        puts "Person Not Found with hbx_id #{hbx_id}"
        next
      end

      family = person.primary_family

      unless person.present?
        puts "Person Not Found with hbx_id #{hbx_id}"
        next
      end
      qle = QualifyingLifeEventKind.where(:market_kind => 'individual', reason: qle_reason).active.last
      raise "Qle with reason #{qle_reason} not found" unless qle.present?

      sep = family.special_enrollment_periods.new(effective_on_kind: qle.effective_on_kinds.first,
                                                  market_kind: sep_type,
                                                  qualifying_life_event_kind: qle,
                                                  qle_on: event_date,
                                                  admin_flag: true,
                                                  coverage_renewal_flag: true)


      sep.effective_on = effective_date if effective_date.present?
      sep.end_on = (event_date + sep_duration.days) if sep_duration.present?

      if sep.save
        family.save!
        p "Successfully crested Special Enrollment Period for person with hbx_id #{hbx_id}"
      else
        p "unable to create SEP for person with hbx_id #{hbx_id} due to #{sep.errors.full_messages.join(', ')})"
      end
    rescue StandardError => e
      p "Rake task failed due to #{e.inspect}"
    end
  end
end
