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
        @orginal_plan_year_begin_date = config["conversions"]["orginal_plan_year_begin_date"]
      end

      def set_original_start_date(coverage_start_date)
        current_year = TimeKeeper.date_of_record.year
        if coverage_start_date
          # to_date parse do not use here
          date = Date.strptime(coverage_start_date, '%m/%d/%Y')
          # since random values given in sheet taking previous year
          start_date = date.change(year: current_year - 1)
          @orginal_plan_year_begin_date = start_date
        else
          @orginal_plan_year_begin_date
        end
      end

      def set_plan_year_end_date(coverage_start_date)
        if coverage_start_date
          @plan_year_end = @orginal_plan_year_begin_date + 1.year - 1.day
        else
          @plan_year_end
        end
      end

      def create_model(record_attrs)
        sheet_given_start_date = set_original_start_date(record_attrs[:coverage_start])
        sheet_given_end_date = set_plan_year_end_date(record_attrs[:coverage_start]) y
        the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase

        plan_year_attrs = record_attrs.merge({
          default_plan_year_start: @default_plan_year_start,
          plan_year_end: sheet_given_end_date,
          mid_year_conversion: @mid_year_conversion,
          orginal_plan_year_begin_date: sheet_given_start_date
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

