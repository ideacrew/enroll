namespace :seed do
  desc "Load the brokers.json file"
  task :broker_json => :environment do
    b_json_file = File.open("db/seedfiles/brokers.json")
    b_json = JSON.load(b_json_file.read)
    b_json.each do |b_rec|
      rec = b_rec.dup
      broker_attrs = rec.delete("broker_role_attributes")
      new_person = Person.new(rec)
      new_person.broker_role = BrokerRole.new(broker_attrs)
      begin
      new_person.save!
      rescue
        raise b_rec.inspect
      end
    end
  end
end
