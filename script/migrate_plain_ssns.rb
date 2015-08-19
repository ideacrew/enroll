class PlainSsnMigrator
  attr_reader :db, :person_collection

  def initialize
    @db = Mongoid::Sessions.default
    @person_collection = @db[:people]
  end

  def migrate_people
    rec = person_collection.find('ssn' => {'$exists' => true})
    rec.each do |r|
      ssn = r['ssn']
      enc_ssn = Person.encrypt_ssn(ssn)
      rec.update("$unset" => {:ssn => true}, "$set" => {:encrypted_ssn => enc_ssn})
    end
  end

  def self.run!
    runner = self.new
    runner.migrate_people
  end

end

PlainSsnMigrator.run!
