require File.join(Rails.root, "lib/mongoid_migration_task")

class DeleteDuplicateWorkflowStateTransitions < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['person_hbx_id']
      person = Person.all.by_hbx_id(hbx_id).first

      if person.nil?
        puts "Unable to find any person record with the given hbx_id: #{hbx_id}" unless Rails.env.test?
        return
      end

      workflow_state_transitions = []
      person.consumer_role.workflow_state_transitions.each do |transition|
        if !workflow_state_transitions.empty?
          workflow_state_transitions.each do |record|
            if record.event == transition.event && record.from_state == transition.from_state && record.to_state == transition.to_state
              transition.destroy
            else
              workflow_state_transitions << transition
            end
          end
        else
          workflow_state_transitions << transition
        end
      end

    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
end
