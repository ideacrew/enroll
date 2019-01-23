require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveDocumentsAssociatedToPerson < MongoidMigrationTask
  def migrate
    hbx_id = ENV['hbx_id']
    doc_id = ENV['doc_id'].to_s
    title =  ENV['title'].to_s.titleize

    person = Person.by_hbx_id(hbx_id).first rescue nil
    document = person.documents.find(doc_id) rescue nil

    if person.present? && document.present?
      puts "Removing Document #{document.title}"
      document.destroy!
      puts "successfully removed document"
    end
  end
end
