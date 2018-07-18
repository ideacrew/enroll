require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateQleTooltip< MongoidMigrationTask

  def migrate
    qles = QualifyingLifeEventKind.where(title: 'Entered into a legal domestic partnership').first
    if qles.present?
      qles.update_attributes(tool_tip: 'Entering a domestic partnership as permitted or recognized by the Massachusetts')
      puts "updated qle tooltip successfully."
    end
  end
end
