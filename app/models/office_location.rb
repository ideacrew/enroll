class OfficeLocation
  include Mongoid::Document

  embedded_in :organization

  field :is_primary, type: Boolean, default: true

  embeds_one :address, cascade_callbacks: true, validate: true
  embeds_one :phone, cascade_callbacks: true, validate: true
  embeds_one :email, cascade_callbacks: true, validate: true

  validates_presence_of :address, :phone

  def is_primary?
    is_primary
  end

end
