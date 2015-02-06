class HbxEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_enrollment

  field :applicant_id, type: BSON::ObjectId
  field :premium_amount_in_cents, type: Integer
  field :is_subscriber, type: Boolean, default: false
  field :eligibility_date, type: Date
  field :start_date, type: Date
  field :end_date, type: Date


  include BelongsToFamilyMember

  #TODO uncomment
  #validates :start_date, presence: true

  validates_presence_of :applicant_id

  #TODO uncomment
  #validate :end_date_gt_start_date

  def end_date_gt_start_date
    if end_date
      if end_date < start_date
        self.errors.add(:base, "The end date should be earlier or equal to start date")
      end
    end
  end

  def family
    return nil unless hbx_enrollment
    hbx_enrollment.family
  end

  def is_subscriber?
    self.is_subscriber
  end

  def premium_amount_in_dollars
    (premium_amount_in_cents/100).round(2) #round currency figure to 2 decimal digits
  end

end
