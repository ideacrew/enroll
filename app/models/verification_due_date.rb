class VerificationDueDate
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :verification_type

  TYPES = %w(admin notice)

  field :due_date, type: Date
  field :updated_by
  field :type, type: String

  validates_presence_of :due_date, :verification_type
  validates :type,
            allow_blank: false,
            inclusion: {
                in: TYPES,
                message: "%{value} is not a valid type"
            }

  def admin_user
    User.find(self.updated_by) if self.updated_by.present?
  end
end