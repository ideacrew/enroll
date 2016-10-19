module Transcripts
  class EnrollmentTranscriptError < StandardError; end

  class EnrollmentTranscript

    attr_accessor :transcript
    include Transcripts::Base

    def initialize
      @transcript = transcript_template

      @logger = Logger.new("#{Rails.root}/log/family_transcript_logfile.log")
      @fields_to_ignore ||= ['_id', 'user_id', 'version', 'created_at', 'updated_at', 'updated_by', 'updated_by_id', 'first_name', 'last_name', 'published_to_bus_at', 'aasm_state', 
        'consumer_role_id', 'carrier_profile_id', 'changing', 'is_active', 'plan_id', 'submitted_at', 'termination_submitted_on']

      @custom_templates = ['HbxEnrollmentMember', 'Plan']
    end

    def convert(record)
      return if record.blank?
      if record.class.to_s == 'Plan'
        {
          :name => record.name,
          :hios_id => record.hios_id,
          :active_year => record.active_year
        }
      else
        {
          :hbx_id => record.family_member.hbx_id,
          :is_subscriber => record.is_subscriber,
          :coverage_start_on => record.coverage_start_on,
          :coverage_end_on => record.coverage_end_on,
          :premium_amount => record.premium_amount,
          :applied_aptc_amount => record.applied_aptc_amount
        }
      end
    end

    def find_or_build(enrollment)
      @transcript[:other] = enrollment
      enrollments = match_instance(enrollment)

      case enrollments.count
      when 0
        @transcript[:source_is_new] = true
        @transcript[:source] = initialize_enrollment
      when 1
        @transcript[:source_is_new] = false
        @transcript[:source] = enrollments.first
      else
        raise "Ambiguous enrollment match: more than one family matches criteria"
      end

      compare_instance
      validate_instance

      if @transcript[:source].persisted?
        find_duplicate_enrollments(@transcript[:source])
      end

      add_plan_information

      @transcript[:source]  = (@transcript[:source]).serializable_hash
      @transcript[:other]   = (@transcript[:other]).serializable_hash
    end

    def add_plan_information
      if @transcript[:compare]['base']  && @transcript[:compare]['base']['update'] && @transcript[:compare]['base']['update']['plan_id'].present?
        plan = @transcript[:other].plan

        @transcript[:compare]['base']['update']['plan_id'] = {
          hios_id: plan.hios_id,
          name: plan.name
        }
      end
    end


    def find_duplicate_enrollments(enrollment)
      enrollments = enrollment.family.active_household.hbx_enrollments.where(:coverage_kind => enrollment.coverage_kind, 
        :kind => enrollment.kind, :id.ne => enrollment.id, 
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)).select{|e| e.plan.active_year == enrollment.plan.active_year}

      return if enrollments.blank?
      @transcript[:compare][:enrollment] ||= {}
      @transcript[:compare][:enrollment][:remove] ||= {}
      @transcript[:compare][:enrollment][:remove][:hbx_id] = enrollments.map{|e| enrollment_hash(e)}
    end

    def enrollment_hash(enrollment)
      {
        hbx_id: enrollment.hbx_id,
        effective_on: enrollment.effective_on,
        hios_id: enrollment.plan.hios_id,
        plan_name: enrollment.plan.name,
        kind: enrollment.kind,
        aasm_state: enrollment.aasm_state.camelcase,
        coverage_kind: enrollment.coverage_kind
      }
    end

    def compare_instance
      return if @transcript[:other].blank?
      differences    = HashWithIndifferentAccess.new

      if @transcript[:source_is_new]
        differences[:new] = {:new => {:hbx_id => @transcript[:other].hbx_id}}
        @transcript[:compare] = differences
        return
      end

      differences[:base] = compare(base_record: @transcript[:source], compare_record: @transcript[:other])

      self.class.enumerated_associations.each do |association|
        differences[association[:association]] = build_association_differences(association)
      end

      @transcript[:compare] = differences
    end


    def self.enumerated_associations
      [
        {association: "plan", enumeration_field: "hios_id", cardinality: "one", enumeration: [ ]},
        # {association: "employer_profile", enumeration_field: "fein", cardinality: "one", enumeration: [ ]},
        {association: "hbx_enrollment_members", enumeration_field: "hbx_id", cardinality: "one", enumeration: [ ]}
      ]
    end

    private

    def match_instance(enrollment)
      primary = enrollment.family.primary_applicant
      enrollments = HbxEnrollment.by_hbx_id(enrollment.hbx_id.to_s)
      primary = enrollments.first.family.primary_applicant if enrollments.present?

      @transcript[:identifier] = enrollment.hbx_id

      if enrollments.present?
        @transcript[:plan_details] = {
          plan_name: "#{enrollments.first.plan.hios_id}:#{enrollments.first.plan.name}",
          effective_on:  enrollments.first.effective_on.strftime("%m/%d/%Y"),
          aasm_state: enrollments.first.aasm_state.camelcase
        }
      end


      @transcript[:primary_details] = {
        hbx_id: primary.person.hbx_id,
        first_name: primary.person.first_name,
        last_name: primary.person.last_name,
        ssn: primary.person.ssn
      }

      enrollments
    end

    def initialize_enrollment
      fields = ::HbxEnrollment.new.fields.inject({}){|data, (key, val)| data[key] = val.default_val; data }
      fields.delete_if{|key,_| @fields_to_ignore.include?(key)}
      ::HbxEnrollment.new(fields)
    end

  end
end