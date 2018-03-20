class IndividualMarketTransition
  include Mongoid::Document
  include Mongoid::Timestamps
  include SetCurrentUser

  embedded_in :person

  ROLE_TYPES   = %W(consumer coverall)
  REASON_CODES = %W(reason1 reason2)

  field :role_type, type: String
  field :effective_starting_on, type: Date
  field :effective_ending_on, type: Date
  field :reason_code, type: String
  field :submitted_at, type: DateTime
  field :user_id, type: BSON::ObjectId

	validates_presence_of :effective_starting_on, :submitted_at

  validates :role_type,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: ROLE_TYPES, message: "%{value} is not a valid individual market role type"}

  validates :reason_code,
          presence: true,
          allow_blank: false,
          allow_nil:   false,
          inclusion: {in: REASON_CODES, message: "%{value} is not a valid transistion reason code"}

  before_save :set_submitted_at

  def set_submitted_at
    self.submitted_at ||= TimeKeeper.datetime_of_record
  end
end
