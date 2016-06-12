module Importers
  class ConversionEmployeePolicyCommon
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_reader :warnings, :fein, :subscriber_ssn, :subscriber_dob, :benefit_begin_date

    attr_accessor :action,
      :default_policy_start,
      :hios_id,
      :plan_year

    include ValueParsers::OptimisticSsnParser.on(:subscriber_ssn, :fein)

    def initialize(opts = {})
      super(opts)
      @warnings = ActiveModel::Errors.new(self)
    end

    def subscriber_dob=(val)
      @subscriber_dob = val.blank? ? nil : (Date.strptime(val, "%m/%d/%Y") rescue nil)
    end

    def benefit_begin_date=(val)
      @benefit_begin_date = val.blank? ? nil : (Date.strptime(val, "%m/%d/%Y") rescue nil)
    end

    def start_date
      [default_policy_start].detect { |item| !item.blank? }
    end
  end
end
