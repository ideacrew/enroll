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

    def validate(params)
      result = ::Validators::Api::SlcspContract.new.call(params)
      return Failure({:message => result.errors.to_h.to_s}) if result.failure?
      Success(result)
    end

    def parse_dob(dob)
      Date.new(dob[:year], dob[:month], dob[:day])
    end

    def process(params)
      result = {}
      primary_member = resolve_primary_member_data(params[:members])
      by_month = reorder_data_by_month(params[:members], primary_member[:residences])
      prev_month_data = {}
      prev_month_value = nil
      @start_dates_by_member = {}
      @first_effective_date = nil
      last_full_result=nil
      (1..12).each do |i|
        month_key = Date::MONTHNAMES[i][0..2].downcase.to_sym
        @logger.info "SLCSP ------------------------- processing month #{month_key}"
        # puts by_month
        current_month_data = by_month[month_key]
        # puts "prev_month_data #{prev_month_data}"
        # puts "current_month_data #{current_month_data}"
        if prev_month_data[:residence] == current_month_data[:residence] && prev_month_data[:members] == current_month_data[:members]
          # house didn't change we can reuse the same result
          result[month_key] = prev_month_value
          next
        else
          recalculate = true
          # something changed we need to recalculate
          if prev_month_data[:residence] != current_month_data[:residence]
            # residence changed we need to recalculate
            @logger.info "SLCSP ------------------------- residence changed"
            # figure it out if we are on a different rating area 
            unless last_full_result.nil?
              seeker=calculate_month(current_month_data, params[:taxYear], i, month_key).value! 
              puts "rating area changed"
              puts "last_full_result #{last_full_result[:service_area_ids]}"
              puts "seeker #{seeker[:service_area_ids]}"
              if last_full_result[:rating_area_id] != seeker[:rating_area_id] && last_full_result[:service_area_ids] != seeker[:service_area_ids]
                # If the change is only to rating area, there's no change in SLCSP. If it's a change in rating + service area (meaning a different SLCSP) 
                # then effective date of the new SLCSP is the month of the change. Does that make sense?
                @start_dates_by_member = {}
                @first_effective_date = nil
                @logger.info "SLCSP ------------------------- rating area changed"
              end 
            end
          end
          if prev_month_data[:members] != current_month_data[:members]
            # members changed we need to recalculate
            @logger.info "SLCSP ------------------------- members changed"
            if current_month_data[:members].blank?
              #gap in coverage, return nil and reset all dates
              @start_dates_by_member = {}
              @first_effective_date = nil
              @current = nil
              recalculate = false
            end
          end
          # prev_month_data = current_month_data.deep_dup
          # puts "before calculate_month #{current_month_data}"
          last_full_result = calculate_month(current_month_data, params[:taxYear], i, month_key).value! if recalculate
          current = last_full_result[:household_group_benchmark_ehb_premium]
        end
        # prev = current.value!
        
        prev_month_data = current_month_data
        result[month_key] = prev_month_value = current
        # params[:members].each do |member|
          
        #   next unless primary_member[:coverage][month_key]
        #   next unless member[:coverage][month_key]
        #   habitants = resolve_cohabitants(params[:members], month_key)
        #   households = organize_households(habitants)
        #   calculation = calculate(households, primary_member, params[:taxYear], params[:state], i, month_key)
        #   result[month_key] = calculation.success? ? calculation.value! : nil
        # end
      end
      Success(result)
    end

    # def compare_members(m1, m2)
    #   m1[:dob] == m2[:dob] && m1[:relationship] == m2[:relationship]
    # end

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
        #this is a little hacky but we need to keep track the coverage start on for each member
        #in case we add or remove people from the household
        # member[:coverage_start_on] = Date.new(assistance_year, month, 1) if member[:coverage_start_on].blank?
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
          county: current_month_data[:residence][:name],
          zip: current_month_data[:residence][:zipcode],
          state: current_month_data[:residence][:state]
        },
        effective_date: @first_effective_date,
        households: [household]
        # households: [
        #   {
        #     household_id: 'a12bs6dbs1',
        #     members: [
        #       {
        #         relationship_with_primary: 'self',
        #         coverage_start_on: Date.new(2022, 1, 1),
        #         date_of_birth: Date.new(1998, 2, 1)
        #       },
        #       {
        #         relationship_with_primary: 'spouse',
        #         coverage_start_on: Date.new(2022, 3, 1),
        #         date_of_birth: Date.new(2002, 2, 10)
        #       }
        #     ]
        #   }
        # ]
      }
    end

    def reorder_data_by_month(members, primary_member)
      result={}
      (1..12).each do |i|
        month_key = Date::MONTHNAMES[i][0..2].downcase.to_sym
        result[month_key] = {
          members: resolve_cohabitants(members, month_key),
          residence: resolve_residence(primary_member, month_key)
        }
      end
      result
    end

    def resolve_residence(residences, month_key)
      residences.each do |residence|
        return residence[:county] if residence[:months][month_key]
      end
    end

    def resolve_cohabitants(members, month_key)
      result = []
      members.each do |member|
        if member[:coverage][month_key]
          info={name: member[:name], relationship: member[:relationship], primary_member: member[:primaryMember], dob: parse_dob(member[:dob])}
          
          # member[:residences].each do |residence|
          #   info[:residence]=residence[:county] if residence[:months][month_key]
          # end
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

    def generate_small_id
      SecureRandom.uuid.gsub("-","")[1..10]
    end

    # def organize_households(members)
    #   result = {}
    #   members.each do |member|
    #     zip = member[:residence][:zipcode]
    #     result[zip] = [] if result[zip].blank?
    #     result[zip] << member 
    #   end
    #   result.values
    # end

    # def calculate(household, primary_member, assistance_year, state, month, month_key)
    #   payload = build_operation_payload(household, primary_member, assistance_year, state, month, month_key)
    #   @logger.info "this is the payload for #{month_key} #{payload}"
    #   result = Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.new.call(payload)
    #   @logger.warn "Unable to calculate SLCSP #{result.failure}"  if result.failure?
    #   return Failure("Unable to calculate SLCSP for #{main_residence_data[:name]}") if result.failure?
    #   Success(result.value![:household_group_benchmark_ehb_premium])
    # end

    # def build_operation_payload(household, primary_member, assistance_year, _state, month, month_key)
    #   main_residence_data = resolve_residence(primary_member[:residences], month_key)
    #   parsed_households = []
    #   household.each do |habitants|
    #     members = []
    #     habitants.each do |habitant|
    #       members << {
    #         relationship_with_primary: habitant[:relationship],
    #         date_of_birth: habitant[:dob]
    #       }
    #     end
    #     parsed_households << {
    #       household_id: generate_id,
    #       members: members
    #     }
    #   end

    #   {
    #     rating_address: {
    #       county: main_residence_data[:name],
    #       zip: main_residence_data[:zipcode],
    #       state: main_residence_data[:state]
    #     },
    #     effective_date: Date.new(assistance_year, month, 1),
    #     households: parsed_households
    #   }
    # end



  end
end