#RAILS_ENV=production bundle exec rake migrations:remove_documents_associated_to_person hbx_id=3383180 message_id="5b52395bf209f24936000016"
require File.join(Rails.root, "app", "data_migrations", "remove_documents_associated_to_person")

 namespace :migrations do 
  desc "remove documents associated to person"
  RemoveDocumentsAssociatedToPerson.define_task :remove_documents_associated_to_person => :environment
end
