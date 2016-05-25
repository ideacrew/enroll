module Importers
  class ConversionEmployerUpdate
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_reader :fein, :broker_npn, :primary_location_zip, :mailing_location_zip

    attr_accessor :action,
      :dba,
      :legal_name,
      :primary_location_address_1,
      :primary_location_address_2,
      :primary_location_city,
      :primary_location_state,
      :mailing_location_address_1,
      :mailing_location_address_2,
      :mailing_location_city,
      :mailing_location_state,
      :contact_email,
      :contact_phone,
      :enrolled_employee_count,
      :new_hire_count,
      :broker_name,
      :contact_first_name,
      :contact_last_name,
      :registered_on

    include Validations::Email

    validates :contact_email, :email => true, :allow_blank => true
    validates_presence_of :contact_first_name, :allow_blank => false
    validates_presence_of :contact_last_name, :allow_blank => false
    validates_presence_of :legal_name, :allow_blank => false
    validates_length_of :fein, is: 9

    attr_reader :warnings

    include ::Importers::ConversionEmployerCarrierValue

    def initialize(opts = {})
      super(opts)
      @warnings = ActiveModel::Errors.new(self)
    end
    
    include ValueParsers::OptimisticSsnParser.on(:fein)

    def broker_npn=(val)
      @broker_npn = Maybe.new(val).strip.extract_value
    end

    ["primary", "mailing"].each do |item|
      class_eval(<<-RUBY_CODE)
      def #{item}_location_zip=(val)
        if val.blank?
          @#{item}_location_zip = nil
          return val
        else
          if val.strip.length == 9 
            @#{item}_location_zip = val[0..4]
          else
            @#{item}_location_zip = val.strip.rjust(5, "0")
          end 
        end
      end
      RUBY_CODE
    end
  end
end
