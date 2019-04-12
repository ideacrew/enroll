class BrokerAgencyProfile
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM
  include Config::AcaModelConcern

  def self.find(id)
  end
end
