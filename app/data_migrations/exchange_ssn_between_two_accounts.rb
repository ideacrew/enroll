require File.join(Rails.root, "lib/mongoid_migration_task")
class ExchangeSsnBetweenTwoAccounts< MongoidMigrationTask
  def migrate
    hbx_id_1=ENV['hbx_id_1']
    hbx_id_2=ENV['hbx_id_2']
    person1 = Person.where(hbx_id:hbx_id_1).first
    person2 = Person.where(hbx_id:hbx_id_2).first
    if person1.nil?
      puts "No person found with hbx_id #{hbx_id_1}"
    elsif person2.nil?
      puts "No person found with hbx_id #{hbx_id_1}"
    else
      ssn1=person1.ssn
      ssn2=person2.ssn
      if ssn1.nil?
        puts "person with hbx_id  #{hbx_id_1} has no ssn"
      elsif ssn2.nil?
        puts "person with hbx_id  #{hbx_id_2} has no ssn"
      else
        temp_ssn=(ssn1.to_i+1).to_s
        person1.update_attributes(ssn:temp_ssn)
        person2.update_attributes(ssn:ssn1)
        person1.update_attributes(ssn:ssn2)
        person1.save
        person2.save
      end
    end
  end
end
