class Household
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :family

  # field :e_pdc_id, type: String  # Eligibility system PDC foreign key

  # embedded belongs_to :irs_group association
  field :irs_group_id, type: BSON::ObjectId

  field :is_active, type: Boolean, default: true

  field :submitted_at, type: DateTime
  field :effective_start_date, type: Date
  field :effective_end_date, type: Date

  embeds_many :coverage_households
  accepts_nested_attributes_for :coverage_households

  embeds_many :hbx_enrollments
  accepts_nested_attributes_for :hbx_enrollments
  
  # embeds_many :tax_households
  # accepts_nested_attributes_for :tax_households
  
  # embeds_many :comments
  # accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  # include HasApplicants

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  def irs_group=(irs_instance)
    return unless irs_instance.is_a? IrsGroup
    self.irs_group_id = irs_instance._id
  end

  def irs_group
    parent.irs_group.find(self.irs_group_id)
  end

  def is_active?
    self.is_active
  end

  def applicant_ids
    th_applicant_ids = tax_households.inject([]) do |acc, th|
      acc + th.applicant_ids
    end
    ch_applicant_ids = coverage_households.inject([]) do |acc, ch|
      acc + ch.applicant_ids
    end
    hbxe_applicant_ids = hbx_enrollments.inject([]) do |acc, he|
      acc + he.applicant_ids
    end
    (th_applicant_ids + ch_applicant_ids + hbxe_applicant_ids).distinct
  end

end
