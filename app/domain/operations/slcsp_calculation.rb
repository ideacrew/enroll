# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'

module Operations
  # This class is invoked when we want to calculate a SLCSP from the api
  # this currently only supports ONE household
  class SlcspCalculation
    include Dry::Monads[:do, :result]

    include Config::SiteHelper

    def call(params)
      @logger = Logger.new($stdout)

      validated_resource = yield validate(params)
      result = yield process(validated_resource.to_h)
      Success(result)
    end

    private

    def validate(params)
      result = ::Validators::Api::SlcspContract.new.call(params)
      return Failure({:message => result.errors.to_h.to_s}) if result.failure?
      Success(result)
    end

    def parse_dob(dob)
      Date.new(dob[:year], dob[:month], dob[:day])
    end

    # rubocop:disable Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/PerceivedComplexity
    def process(params)
      result = {}
      primary_member = resolve_primary_member_data(params[:members])
      by_month = reorder_data_by_month(params[:members], primary_member[:residences])
      prev_month_data = {}
      prev_month_value = nil
      @start_dates_by_member = {}
      @first_effective_date = nil
      last_full_result = nil
      (1..12).each do |i|
        month_key = Date::MONTHNAMES[i][0..2].downcase.to_sym
        @logger.info "SLCSP ------------------------- processing month #{month_key}"
        current_month_data = by_month[month_key]
        if prev_month_data[:residence] == current_month_data[:residence] && prev_month_data[:members] == current_month_data[:members]
          # house didn't change we can reuse the same result
          result[month_key] = prev_month_value
          next
        else
          recalculate = true
          # something changed we need to recalculate
          if prev_month_data[:residence] != current_month_data[:residence] && !last_full_result.nil? && !current_month_data[:members].blank? && !current_month_data[:primary_absent]
            @logger.info "SLCSP ------------------------- residence changed"
            # figure it out if we are on a different rating area
            seeker = {}
            seeker_call = calculate_month(current_month_data, params[:taxYear], i, month_key)
            seeker = seeker_call.value! if seeker_call.success?
            if last_full_result[:rating_area_id] != seeker[:rating_area_id] && last_full_result[:service_area_ids] != seeker[:service_area_ids]
              # If the change is only to rating area, there's no change in SLCSP. If it's a change in rating + service area (meaning a different SLCSP)
              # then effective date of the new SLCSP is the month of the change.
              @start_dates_by_member = {}
              @first_effective_date = nil
            end
          end
          if prev_month_data[:members] != current_month_data[:members] && current_month_data[:members].blank?
            @logger.info "SLCSP ------------------------- gap in coverage"
            @start_dates_by_member = {}
            @first_effective_date = nil
            current = nil
            recalculate = false
          end
          last_call = calculate_month(current_month_data, params[:taxYear], i, month_key) if recalculate
          if recalculate && last_call.success?
            last_full_result = last_call.value!
            current = last_full_result[:household_group_benchmark_ehb_premium]
          else
            current = nil
            current = "Lived in another country or was deceased" if current_month_data[:primary_absent]
            current = "Lived in a different state" if current.blank? && in_different_state?(params, current_month_data)
          end
        end

        prev_month_data = current_month_data
        result[month_key] = prev_month_value = current
      end
      Success(result)
    end
    # rubocop:enable Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/PerceivedComplexity

    def calculate_month(current_month_data, assistance_year, month, month_key)
      payload = build_operation_payload(current_month_data, assistance_year, month)
      @logger.info "this is the payload for #{month_key} #{payload}"
      result = Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.new.call(payload)
      @logger.warn "Unable to calculate SLCSP #{result.failure}"  if result.failure?
      return Failure("Unable to calculate SLCSP for #{current_month_data}") if result.failure?
      Success(result.value!)
    end

    def build_operation_payload(current_month_data, assistance_year, month)
      household = {
        household_id: generate_small_id,
        members: []
      }

      current_month_data[:members].each do |member|
        @start_dates_by_member["#{member[:dob]}-#{member[:relationship]}"] = Date.new(assistance_year, month, 1) if @start_dates_by_member["#{member[:dob]}-#{member[:relationship]}"].blank?

        household[:members] << {
          relationship_with_primary: member[:relationship],
          date_of_birth: member[:dob],
          coverage_start_on: @start_dates_by_member["#{member[:dob]}-#{member[:relationship]}"]
        }
      end

      @first_effective_date = Date.new(assistance_year, month, 1) if @first_effective_date.blank?
      {
        rating_address: {
          county: county_name_hack(current_month_data[:residence][:name]),
          zip: current_month_data[:residence][:zipcode],
          state: current_month_data[:residence][:state]
        },
        effective_date: @first_effective_date,
        households: [household]
      }
    end

    def county_name_hack(county_name)
      # our counties don't have the word county on them :)
      return county_name.gsub(/county/i, '').strip unless county_name.blank?
    end

    def reorder_data_by_month(members, primary_member)
      result = {}
      (1..12).each do |i|
        month_key = Date::MONTHNAMES[i][0..2].downcase.to_sym
        primary_residence = resolve_residence(primary_member, month_key)
        result[month_key] = {
          members: resolve_cohabitants(members, month_key),
          residence: primary_residence&.dig(:county),
          primary_absent: primary_residence&.dig(:absent)
        }
      end
      result
    end

    def resolve_residence(residences, month_key)
      residences.each do |residence|
        return residence if residence[:months][month_key]
      end
      nil
    end

    def resolve_cohabitants(members, month_key)
      result = []
      members.each do |member|
        if member[:coverage][month_key]
          info = {name: member[:name], relationship: member[:relationship], primary_member: member[:primaryMember], dob: parse_dob(member[:dob])}
          result << info
        end
      end
      result
    end

    def resolve_primary_member_data(members)
      members.each do |member|
        return member if member[:primaryMember]
      end
    end

    def in_different_state?(params, current_month_data)
      return true if current_month_data.blank?
      return true if current_month_data[:residence].blank?
      return true if current_month_data[:residence][:state].blank?

      estimate_state = params[:state].downcase
      address_state = current_month_data[:residence][:state].downcase

      address_state != estimate_state
    end

    def generate_small_id
      SecureRandom.uuid.gsub("-","")[1..10]
    end
  end
end