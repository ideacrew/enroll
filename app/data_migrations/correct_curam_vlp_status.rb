require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectCuramVlpStatus < MongoidMigrationTask
  def migrate
    puts "MIGRATION"
  end
end
