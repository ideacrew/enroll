class BrokerBuilder

  attr_reader :person

  def initialize(broker_hash)
    @broker_hash = broker_hash
  end

  def build
    @person = Person.new({first_name: @broker_hash[:name][:first_name], last_name: @broker_hash[:name][:last_name]})

    @broker_hash[:phones].each do |phone|
      @person.phones.build(phone)
    end
    @broker_hash[:emails].each do |email|
      @person.emails.build(email)
    end

    @person.broker_role = BrokerRole.new({npn:@broker_hash[:npn]})
  end

  def save
    @person.save
  end

  def broker
    @person.broker_role
  end
end