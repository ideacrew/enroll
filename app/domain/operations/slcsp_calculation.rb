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
      primary_member = resolve_primary_member_data(params[:members])
      (1..12).each do |i|
        month_key = Date::MONTHNAMES[i][0..2].downcase.to_sym
        params[:members].each do |member|
          next unless primary_member[:coverage][month_key]
          next unless member[:coverage][month_key]
          habitants = resolve_cohabitants(params[:members], month_key)
          households = organize_households(habitants)
          calculation = calculate(households, primary_member, params[:taxYear], params[:state], i, month_key)
          result[month_key] = calculation.success? ? calculation.value! : nil
        end
      end
      Success(result)
    end

    def resolve_cohabitants(members, month_key)
      result = []
      members.each do |member|
        if member[:coverage][month_key]
          info={name: member[:name], relationship: member[:relationship], primary_member: member[:primaryMember], dob: parse_dob(member[:dob])}
          member[:residences].each do |residence|
            info[:residence]=residence[:county] if residence[:months][month_key]
          end
          result << info
        end
      end
      result
    end

    def resolve_primary_member_data(members)
      members.each do |member|
        puts member
        return member if member[:primaryMember]
      end
    end

    def organize_households(members)
      result = {}
      members.each do |member|
        zip = member[:residence][:zipcode]
        result[zip] = [] if result[zip].blank?
        result[zip] << member 
      end
      result.values
    end

    def parse_dob(dob)
      Date.new(dob[:year], dob[:month], dob[:day])
    end

    def calculate(household, primary_member, assistance_year, state, month, month_key)
      payload = build_operation_payload(household, primary_member, assistance_year, state, month, month_key)
      @logger.info "this is the payload for #{month_key} #{payload}"
      result = Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.new.call(payload)
      @logger.warn "Unable to calculate SLCSP #{result.failure}"  if result.failure?
      return Failure("Unable to calculate SLCSP for #{main_residence_data[:name]}") if result.failure?
      Success(result.value![:household_group_benchmark_ehb_premium])
    end

    def build_operation_payload(household, primary_member, assistance_year, _state, month, month_key)
      main_residence_data = resolve_residence(primary_member[:residences], month_key)
      parsed_households = []
      household.each do |habitants|
        members = []
        habitants.each do |habitant|
          members << {
            relationship_with_primary: habitant[:relationship],
            date_of_birth: habitant[:dob]
          }
        end
        parsed_households << {
          household_id: generate_id,
          members: members
        }
      end

      {
        rating_address: {
          county: main_residence_data[:name],
          zip: main_residence_data[:zipcode],
          state: main_residence_data[:state]
        },
        effective_date: Date.new(assistance_year, month, 1),
        households: parsed_households
      }
    end

    def resolve_residence(residences, month_key)
      residences.each do |residence|
        return residence[:county] if residence[:months][month_key]
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