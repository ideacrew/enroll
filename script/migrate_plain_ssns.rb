class PlainSsnMigrator
  attr_reader :db, :person_collection, :census_collection

  def initialize
    @db = Mongoid::Sessions.default
    @person_collection = @db[:people]
    @census_collection = @db[:census_members]
  end

  def migrate_people
    recs = person_collection.find('ssn' => {'$exists' => true})
    recs.each do |r|
      ssn = r['ssn']
      enc_ssn = Person.encrypt_ssn(ssn)
      r.update("$unset" => {:ssn => true}, "$set" => {:encrypted_ssn => enc_ssn})
    end
  end

  def migrate_dependents
    recs = census_collection.find('census_dependents.ssn' => {'$exists' => true})
    recs.each do |r|
      deps = r['census_dependents']
      rec_id = r['_id']
      updated_records = {}
      if !deps.empty?
        deps.each do |d|
           id = d['_id']
           ssn = d['ssn']
           if !ssn.blank?
             updated_records[id] = ssn
           end
        end
      end
      updated_records.each_pair do |k, v|
        census_collection.where(
          { 
            "_id" => rec_id,
            "census_dependents._id" => k
          }).update( 
          { "$unset" =>
            {'census_dependents.$.ssn' => true},
            "$set" =>
              {'census_dependents.$.encrypted_ssn' => CensusMember.encrypt_ssn(v)}
          }
        )
      end
    end
  end

  def migrate_employees
    recs = census_collection.find('ssn' => {'$exists' => true})
    recs.each do |r|
      ssn = r['ssn']
      enc_ssn = Person.encrypt_ssn(ssn)
      r.update("$unset" => {:ssn => true}, "$set" => {:encrypted_ssn => enc_ssn})
    end
  end

  def self.run!
    runner = self.new
    runner.migrate_people
    runner.migrate_employees
    runner.migrate_dependents
  end

end

PlainSsnMigrator.run!
