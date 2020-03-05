class Phone
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  embedded_in :person
  embedded_in :office_location
  embedded_in :census_member, class_name: "CensusMember"

  KINDS = ["home", "work", "mobile", "main", "fax"]
  OFFICE_KINDS = ["phone main"]

  field :kind, type: String
  field :country_code, type: String, default: ""
  field :area_code, type: String, default: ""
  field :number, type: String, default: ""
  field :extension, type: String, default: ""
  field :primary, type: Boolean
  field :full_phone_number, type: String, default: ""

  track_history :on => [:fields],
                :scope => :person,
                :modifier_field => :modifier,
                :modifier_field_optional => true,
                :version_field => :tracking_version,
                :track_create  => true,    # track document creation, default is false
                :track_update  => true,    # track document updates, default is true
                :track_destroy => true

  before_validation :save_phone_components

  before_save :set_full_phone_number

  validates :area_code,
    numericality: true,
    length: { minimum: 3, maximum: 3, message: "%{value} is not a valid area code" },
    allow_blank: false

  validates :number,
    numericality: true,
    length: { minimum: 7, maximum: 7, message: "%{value} is not a valid phone number" },
    allow_blank: false

  validate :validate_phone_kind

  def blank?
    [:full_phone_number, :area_code, :number, :extension].all? do |attr|
      self.send(attr).blank?
    end
  end

  def save_phone_components
    phone_number = filter_non_numeric(self.full_phone_number).to_s
    if !phone_number.blank?
      length=phone_number.length
      if length>10
        self.area_code = phone_number[0,3]
        self.number = phone_number[3,7]
        self.extension = phone_number[10,length-10]
      elsif length==10
        self.area_code = phone_number[0,3]
        self.number = phone_number[3,7]
        self.extension = ""
      end
    end
  end

  def full_phone_number=(new_full_phone_number)
   super filter_non_numeric(new_full_phone_number)
   save_phone_components
  end

  def area_code=(new_area_code)
   super filter_non_numeric(new_area_code)
  end

  def number=(new_number)
   super filter_non_numeric(new_number)
  end

  def extension=(new_extension)
   super filter_non_numeric(new_extension)
  end

  def to_s
    full_number = (self.area_code + self.number).to_i
    if self.extension.present?
      full_number.to_s(:phone, area_code: true, extension: self.extension)
    else
      full_number.to_s(:phone, area_code: true)
    end
  end

  def set_full_phone_number
    self.full_phone_number = to_s
  end

  def is_only_individual_person_phone?
    person_is_phone_parent = self._parent.class == Person
    if person_is_phone_parent
      phone_number_is_not_broker_role_number = if _parent&.broker_role&.phone.respond_to?(:full_phone_number)
                                               _parent&.broker_role&.phone.full_phone_number != full_phone_number
                                             elsif _parent.broker_role
                                               # Needs to compensate because the broker_agency_profile
                                               # wont be a phone instance that responds to full_phone_number
                                               # but a string like "(111) 111-1111 x 3"
                                               _parent.broker_role.phone.scan(/\d/).join.exclude?(full_phone_number)
                                             else # No broker role present
                                               true
                                             end
      # person has many general_agency_staff_roles, which belong to general_agency_profile, which has a method #phone
      # attached to it which calls office = organization.primary_office_location office && office.phone.to_s with a string like
      # (111) 111-1111
      phone_is_not_general_agency_staff_role_number = if _parent.general_agency_staff_roles.count > 0
                                                      not_ga_staff_number = true
                                                      _parent.general_agency_staff_roles.each do |general_agency_staff_role|
                                                        general_agency_primary_staff_person =  general_agency_staff_role&.general_agency_profile&.primary_staff&.person
                                                        # general_agency_primary_staff_person_phone = general_agency_primary_staff_person&.phone&.scan(/\d/)&.join
                                                        ga_profile_phone = general_agency_staff_role&.general_agency_profile&.phone&.scan(/\d/)&.join
                                                        kind_being_updated = self.kind
                                                        if ga_profile_phone&.include?(full_phone_number)
                                                          not_ga_staff_number = false
                                                          # Use case: General Agency Phone number listed as "home",
                                                          # but is the main contact for the agency.
                                                          # allow the kind to be updated to "phone main"
                                                          # see profiles_controller_spec "should update person main phone"
                                                        elsif KINDS.exclude?(kind_being_updated)
                                                          not_ga_staff_number = false
                                                        end
                                                      end
                                                      not_ga_staff_number
                                                    else
                                                      true
                                                    end
      # all? will return false if any value is nil or false
      [person_is_phone_parent, phone_number_is_not_broker_role_number, phone_is_not_general_agency_staff_role_number].all?
    end
  end

  private

  def validate_phone_kind
    # "phone main" is invalid EDI for individual person phones
    if self.is_only_individual_person_phone?
      errors.add(:kind, "#{kind} is not a valid phone type") unless kind.in?(KINDS)
    else # is an office
      errors.add(:kind, "#{kind} is not a valid phone type") unless kind.in?(KINDS + OFFICE_KINDS)
    end
  end
  
  def filter_non_numeric(str)
    str.present? ? str.to_s.gsub(/\D/,'') : ""
  end
end
