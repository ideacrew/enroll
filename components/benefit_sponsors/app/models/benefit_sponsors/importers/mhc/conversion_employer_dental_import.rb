module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerDentalImport < ConversionEmployerPlanYearSet

      def create_model(record_attrs)
        if @mid_year_conversion
          recalc_plan_year_dates_from_sheet(record_attrs[:coverage_start])
        end

        the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase

        plan_year_attrs = record_attrs.merge({
                                                 default_plan_year_start: @default_plan_year_start,
                                                 plan_year_end: @plan_year_end,
                                                 mid_year_conversion: @mid_year_conversion,
                                                 orginal_plan_year_begin_date: @orginal_plan_year_begin_date
                                             })

        case the_action
        when "add"
          ConversionEmployerDentalInitializer.new(plan_year_attrs)
        else
          raise "Unknown action"
        end
      end

    end
  end
end