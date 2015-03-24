module Forms
  class Address
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :kind
    attr_accessor :address_1, :address_2, :city, :state, :zip

    validates :kind,
      inclusion: { in: ::Address::KINDS, message: '%{value} is not a valid address kind' },
      allow_blank: false

    validates :zip,
      format: {
      :with => /\A\d{5}(-\d{4})?\z/,
      :message => "should be in the form: 12345 or 12345-1234"
    }

    validates_presence_of :address_1, :city, :state, :zip
  end
end
