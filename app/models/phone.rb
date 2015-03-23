class Phone
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person
  embedded_in :office_location
  embedded_in :employer_census_member, class_name: "EmployerCensus::Member"

  KINDS = ["home", "work", "mobile", "main", "fax"]

  field :kind, type: String
  field :country_code, type: String, default: ""
  field :area_code, type: String, default: ""
  field :number, type: String
  field :extension, type: String, default: ""
  field :primary, type: Boolean
  field :full_phone_number, type: String, default: ""

  before_validation :save_phone_components

  validates :area_code,
    numericality: true,
    length: { minimum: 3, maximum: 3, message: "%{value} is not a valid area code" },
    allow_blank: false

  validates :number,
    numericality: true,
    length: { minimum: 7, maximum: 7, message: "%{value} is not a valid phone number" },
    allow_blank: false

  validates :kind,
    inclusion: { in: KINDS, message: "%{value} is not a valid phone type" },
    allow_blank: false

  def save_phone_components
    phone_number = filter_non_numeric(self.full_phone_number).to_s
    if !phone_number.blank?
      case phone_number.length
      when 11
        self.country_code = phone_number[0,1]
        self.area_code = phone_number[1,3]
        self.number = phone_number[4,7]
      when 10
        self.area_code = phone_number[0,3]
        self.number = phone_number[3,7]
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

private
  def filter_non_numeric(str)
    str.to_s.gsub(/\D/,'') if str.present? 
  end
end
