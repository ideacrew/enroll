class Person

  include Mongoid::Document
  include Mongoid::Timestamps

  field :hbx_id, type: String
  field :name_pfx, type: String
  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :name_sfx, type: String
  field :full_name, type: String
  field :alternate_name, type: String

  # Sub-model in-common attributes
  field :encrypted_ssn, type: String
  field :dob, type: Date
  field :gender, type: String
  field :date_of_death, type: Date
  field :dob_check, type: Boolean

  field :is_incarcerated, type: Boolean

  field :is_disabled, type: Boolean
  field :ethnicity, type: Array
  field :race, type: String
  field :tribal_id, type: String

  field :is_tobacco_user, type: String, default: "unknown"
  field :language_code, type: String

  field :no_dc_address, type: Boolean, default: false
  field :no_dc_address_reason, type: String, default: ""

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String
  field :no_ssn, type: String #ConsumerRole TODO TODOJF
  field :is_physically_disabled, type: Boolean


  delegate :is_applying_coverage, to: :consumer_role, allow_nil: true

  # Login account
  belongs_to :user
  embeds_one :broker_role, cascade_callbacks: true, validate: true
  embeds_many :addresses, cascade_callbacks: true, validate: true
  embeds_many :phones, cascade_callbacks: true, validate: true
  embeds_many :emails, cascade_callbacks: true, validate: true

  accepts_nested_attributes_for :phones, :reject_if => Proc.new { |addy| Phone.new(addy).blank? }
  accepts_nested_attributes_for :addresses, :reject_if => Proc.new { |addy| Address.new(addy).blank? }
  accepts_nested_attributes_for :emails, :reject_if => Proc.new { |addy| Email.new(addy).blank? }
end
