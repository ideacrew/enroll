module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerPlanYearSet < ::Importers::Mhc::ConversionEmployerPlanYearSet

      def initialize(file_name, o_stream, config)
        @spreadsheet = Roo::Spreadsheet.open(file_name)
        @out_stream = o_stream
        @out_csv = CSV.new(o_stream)
        @default_plan_year_start = config["conversions"]["plan_year_date"]
        @plan_year_end = config["conversions"]["plan_year_end_date"]
        @mid_year_conversion = config["conversions"]["mid_year_conversion"]
      end

      def create_model(record_attrs)
        the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase

        plan_year_attrs = record_attrs.merge({
          default_plan_year_start: @default_plan_year_start,
          plan_year_end: @plan_year_end,
          mid_year_conversion: @mid_year_conversion 
          })

        case the_action
        when "update"
          ::Importers::Mhc::ConversionEmployerPlanYearUpdate.new(plan_year_attrs)
        else
          ConversionEmployerPlanYearCreate.new(plan_year_attrs)
        end
      end
    end
  end
end

