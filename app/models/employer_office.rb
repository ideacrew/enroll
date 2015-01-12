class EmployerOffice
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer

  field :location_name, type: String

  embeds_one :address
end
