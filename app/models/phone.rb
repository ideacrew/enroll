class Phone
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  embedded_in :person

  KINDS = ["home", "work", "mobile", "fax"]

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
    phone_number = filter_non_numbers(self.full_phone_number)
    if phone_number && phone_number.length == 10
      self.area_code = phone_number[0,3].to_i
      self.number = phone_number[3,9].to_i
    end
  end
  
  #def area_code=(value)
   # super filter_non_numbers(value)
  #end

  #def number=(value)
   # super filter_non_numbers(value)
  #end

  #def extension=(value)
   # super filter_non_numbers(value)
  #end

private
  def filter_non_numbers(str)
    str.gsub(/\D/,'') if str.present?
  end
end
