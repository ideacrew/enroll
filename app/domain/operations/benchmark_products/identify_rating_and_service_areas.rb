# frozen_string_literal: true

module Operations
  module BenchmarkProducts
    # This Operation is used to identify rating area and service areas for rating_address of Primary Person of Family
    class IdentifyRatingAndServiceAreas
      include Dry::Monads[:result, :do]

      def call(params)
        # params = { family: family, benchmark_product_model: benchmark_product_model }
        bpm_params, rating_address = yield find_rating_address(params)
        bpm_params                 = yield find_rating_area(rating_address, bpm_params)
        bpm_params                 = yield find_service_areas(rating_address, bpm_params)
        benchmark_product_model    = yield initialize_benchmark_product_model(bpm_params)

        Success(benchmark_product_model)
      end

      private

      def find_rating_address(params)
        family = params[:family]
        bpm_params = params[:benchmark_product_model].to_h
        rating_address = family.primary_person&.rating_address
        if rating_address.present?
          bpm_params[:primary_rating_address_id] = rating_address.id
          Success([bpm_params, rating_address])
        else
          Failure("Unable to find Rating Address for Primary Person with hbx_id: #{family.primary_person.hbx_id} of Family with id: #{family.id}")
        end
      end

      def find_rating_area(address, bpm_params)
        effective_date = bpm_params[:effective_date]
        rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_date)

        if rating_area.present?
          bpm_params[:rating_area_id] = rating_area.id
          bpm_params[:exchange_provided_code] = rating_area.exchange_provided_code
          Success(bpm_params)
        else
          Failure("Rating Area not found for effective_date: #{effective_date}, county: #{address.county}, zip: #{address.zip}")
        end
      end

      def find_service_areas(address, bpm_params)
        effective_date = bpm_params[:effective_date]
        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_date)

        if service_areas.present?
          bpm_params[:service_area_ids] = service_areas.map(&:id)
          Success(bpm_params)
        else
          Failure("Service Areas not found for effective_date: #{effective_date}, county: #{address.county}, zip: #{address.zip}")
        end
      end

      def initialize_benchmark_product_model(bpm_params)
        ::Operations::BenchmarkProducts::Initialize.new.call(bpm_params)
      end
    end
  end
end
