class EmployerStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers
  extend Acapi::Notifiers

  after_update :notify_contact_changed
  embedded_in :person
  field :is_owner, type: Boolean, default: true
  field :employer_profile_id, type: BSON::ObjectId
  field :bookmark_url, type: String
  field :is_active, type: Boolean, default: true
  field :benefit_sponsor_employer_profile_id, type: BSON::ObjectId

  validates_presence_of :employer_profile_id, :if => Proc.new { |m| m.benefit_sponsor_employer_profile_id.blank? }
  validates_presence_of :benefit_sponsor_employer_profile_id, :if => Proc.new { |m| m.employer_profile_id.blank? }

  field :aasm_state, type: String, default: 'is_active'
  scope :active, ->{ where(aasm_state: :is_active) }
  aasm do
    state :is_applicant    #Person has requested employer staff role with this company
    state :is_active     #Person has created a company, or been added, or request has been approved
    state :is_closed	  #Person employer staff role is not active

    event :approve do
      transitions from: [:is_applicant, :is_active], to: :is_active
    end
    event :close_role do
      transitions from: [:is_applicant, :is_active, :is_closed], to: :is_closed
    end
  end

  def current_state
    aasm_state.humanize.titleize
  end

  def notify_contact_changed
    notify("acapi.info.events.employer.contact_changed", {employer_id: find_hbx_id_with_profile_id , event_name: "contact_changed"})
  end

  def find_hbx_id_with_profile_id
    if benefit_sponsor_employer_profile_id.present?
      BenefitSponsors::Organizations::Profile.find(self.benefit_sponsor_employer_profile_id).hbx_id
    elsif employer_profile_id.present?
      EmployerProfile.find(self.employer_profile_id).hbx_id
    end
  end
end