
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeSuffixPerson < MongoidMigrationTask
  def migrate
    puts "updating person suffix" unless Rails.env.test?
    hbx_id = [
      "19760877", "19776645", "19747772", "19758664", "19776417",
       "18941825", "19766429", "19761376", "19753221", "19762647",
        "19775694", "19757825", "19749172", "19772583", "19771579",
         "19745475", "19744827", "19761611", "19763400", "19773230",
          "19743457", "2085463", "19753992", "2166772", "19771972",
           "19756452", "19771773", "19759229", "19753432", "19760652",
            "18942772", "19759405", "19771826", "19743273"
          ]
    hbx_id.each do |hbx|
      person = Person.where(hbx_id: hbx).first
      if person.present?
        person.update_attributes(name_sfx: "")
        person.save
      else
        puts "Person not found for hbx_id #{hbx}"
      end
      unless Rails.env.test?
        puts "Updated person Suffix"
      end
    end
  end
end
