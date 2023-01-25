# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'

module Operations
  # This class is invoked when we want to calculate a SLCSP from the api
  class SlcspCalculation
    send(:include, Dry::Monads[:result, :do, :try])

    include Config::SiteHelper

    def call(params)
      @logger = Logger.new($stdout)

      validated_resource = yield validate(params)
      result = yield process(validated_resource.to_h)
      Success(result)
    end

    private

    def process(params)
      result = {}
      (1..12).each do |i|
        month_key = Date::MONTHNAMES[i][0..2].downcase.to_sym
        params[:members].each do |member|
          next unless member[:coverage][month_key]
          calculation = calculate(member, params[:taxYear], params[:state], i, month_key)
          result[month_key] = calculation.success? ? calculation.value! : 0
        end
      end
      Success(result)
    end

    def calculate(member, assistance_year, state, month, month_key)
      payload = build_operation_payload(member, assistance_year, state, month, month_key)
      result = Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.new.call(payload)
      @logger.warn "Unable to calculate SLCSP #{result.failure}"  if result.failure?
      return Failure("Unable to calculate SLCSP for #{member[:name]}") if result.failure?
      Success(result.value![:household_group_benchmark_ehb_premium])
    end

    def build_operation_payload(member, assistance_year, _state, month, month_key)
      residence_data = resolve_residence(member[:residences], month_key)
      dob = Date.new(member[:dob][:year], member[:dob][:month], member[:dob][:day])
      {
        rating_address: {
          county: residence_data[:county][:name],
          zip: residence_data[:county][:zipcode],
          state: residence_data[:county][:state]
        },
        effective_date: Date.new(assistance_year, month, 1),
        households: [
            {
              household_id: generate_id,
              members: [
                {
                  relationship_with_primary: 'self',
                  date_of_birth: dob
                }
              ]
            }
          ]
      }
    end

    def resolve_residence(residences, month_key)
      residences.each do |residence|
        return residence if residence[:months][month_key]
      end
    end

    def generate_id
      SecureRandom.uuid.gsub("-","")[1..10]
    end

    def validate(params)
      result = ::Validators::Api::SlcspContract.new.call(params)
      return Failure({:message => result.errors.to_h.to_s}) if result.failure?
      Success(result)
    end

  end
end