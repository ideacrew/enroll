class SpecialEnrollmentPeriod
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :family

  # Date Qualifying Life Event occured
  field :qle_on, type: Date

  field :qualifying_life_event_kind_id, type: BSON::ObjectId

  # Date Special Enrollment Period starts
  field :begin_on, type: Date

  # Date Special Enrollment Period ends
  field :end_on, type: Date

  # Date coverage takes effect
  field :effective_on, type: Date

  # Timestamp when SEP was reported to HBX
  field :submitted_at, type: DateTime

  field :effective_on_kind, type: String

  validates_presence_of :qle_on, :begin_on, :end_on, :effective_on
  validate :end_date_follows_begin_date

  before_create :set_submitted_at

  def qualifying_life_event_kind=(new_qualifying_life_event_kind)
    raise ArgumentError.new("expected QualifyingLifeEventKind") unless new_qualifying_life_event_kind.is_a?(QualifyingLifeEventKind)
    self.qualifying_life_event_kind_id = new_qualifying_life_event_kind._id
    set_sep_dates
    new_qualifying_life_event_kind
    @qualifying_life_event_kind = new_qualifying_life_event_kind
  end

  def qualifying_life_event_kind
    return @qualifying_life_event_kind if defined? @qualifying_life_event_kind
    @qualifying_life_event_kind = QualifyingLifeEventKind.find(self.qualifying_life_event_kind_id)
  end

  def qle_on=(new_qle_date)
    write_attribute(:qle_on, new_qle_date)
    set_sep_dates
    self.qle_on
  end

  def set_sep_dates
    return unless self.qle_on.present? && self.qualifying_life_event_kind_id.present?
    set_begin_and_end_on
    set_effective_on
    set_submitted_at
  end

  def is_active?
    return false if self.begin_on.blank? || self.end_on.blank?
    (self.begin_on..self.end_on).include?(Date.today)
  end

  def duration_in_days
    self.end_on - self.begin_on
  end

private
  def set_begin_and_end_on
    self.begin_on = self.qle_on - self.qualifying_life_event_kind.pre_event_sep_in_days
    self.end_on = self.begin_on + qualifying_life_event_kind.post_event_sep_in_days
  end

  def set_effective_on
    return unless self.begin_on.present? && self.qualifying_life_event_kind.present?

    self.effective_on = case self.effective_on_kind
                        when "date_of_event"
                          qle_on
                        when "first_of_this_month"
                          qle_on.beginning_of_month
                        when "first_of_next_month"
                          qle_on.end_of_month + 1.day
                        end
  end

  def end_date_follows_begin_date
    return unless self.end_on.present?
    # Passes validation if end_on == start_date
    errors.add(:end_on, "end_on cannot preceed begin_on date") if self.end_on < self.begin_on
  end

  def set_submitted_at
    self.submitted_at ||= Time.now
  end

end
