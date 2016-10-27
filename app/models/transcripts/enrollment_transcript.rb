module Transcripts
  class EnrollmentTranscriptError < StandardError; end

  class EnrollmentTranscript

    attr_accessor :transcript, :shop
    include Transcripts::Base

    def initialize
      @transcript = transcript_template

      @logger = Logger.new("#{Rails.root}/log/family_transcript_logfile.log")
      @fields_to_ignore ||= ['_id', 'user_id', 'version', 'created_at', 'updated_at', 'updated_by', 'updated_by_id', 'published_to_bus_at', 'aasm_state', 
        'consumer_role_id', 'carrier_profile_id', 'changing', 'is_active', 'plan_id', 'submitted_at', 'termination_submitted_on', 'enrollment_kind', 'elected_aptc_pct', 
        'review_status', 'enrollment_signature', 'special_verification_period', 'special_enrollment_period_id','employee_role_id', 'benefit_group_id', 
        'benefit_group_assignment_id',
        'broker_agency_profile_id',
        'original_application_type',
        'terminate_reason',
        'waiver_reason',
        'writing_agent_id',
        'coverage_end_on']

      @custom_templates = ['HbxEnrollmentMember', 'Plan', 'BrokerRole']

      if @shop
        @fields_to_ignore << 'applied_aptc_amount'
        @custom_templates << 'EmployerProfile'
      end
    end

    def convert(record)
      return if record.blank?
      if record.class.to_s == 'Plan'
        {
          :name => record.name,
          :hios_id => record.hios_id,
          :active_year => record.active_year
        }
      elsif record.class.to_s == 'EmployerProfile'
        {
          :fein => record.fein,
          :legal_name => record.legal_name
        }
      elsif record.class.to_s == 'BrokerRole'
         {
          :npn => record.npn,
          :first_name => record.person.first_name,
          :last_name => record.person.last_name
        }
      else
        {
          :hbx_id => record.family_member.hbx_id,
          :is_subscriber => record.is_subscriber,
          :coverage_start_on => record.coverage_start_on,
          :coverage_end_on => record.coverage_end_on,
          :premium_amount => (record.persisted? ? record.hbx_enrollment.premium_for(record) : record.premium_amount.to_f)
          # :applied_aptc_amount => record.applied_aptc_amount
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
      # validate_instance

      if @transcript[:source].persisted?
        find_duplicate_enrollments(@transcript[:source])
      end

      add_plan_information

      @transcript[:source]  = @transcript[:source].serializable_hash
      @transcript[:other]   = @transcript[:other].serializable_hash
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
      if @shop
        assignment = enrollment.benefit_group_assignment
        id_list = assignment.benefit_group.plan_year.benefit_groups.collect(&:_id).uniq

        enrollments = enrollment.family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).where({
          :coverage_kind => enrollment.coverage_kind, 
          :id.ne => enrollment.id,
          :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
          })

      else
        enrollments = enrollment.family.active_household.hbx_enrollments.where({
          :coverage_kind => enrollment.coverage_kind, 
          :kind => enrollment.kind, 
          :id.ne => enrollment.id, 
          :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
          }).select{|e| e.plan.active_year == enrollment.plan.active_year}
      end
     
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


    def compare_assocation(source, other, differences, attr_val)
      assoc_class = (source || other).class.to_s
      if @custom_templates.include?(assoc_class)
        source = convert(source)
        other = convert(other)
      end

      if source.present? || other.present?
        if source.blank?
          differences[:add] ||= {}
          differences[:add][attr_val] = (other.is_a?(Hash) ? other : other.serializable_hash)
        elsif other.blank?
          differences[:remove] ||= {}
          differences[:remove][attr_val] = (source.is_a?(Hash) ? source : source.serializable_hash)
        elsif source.present? && other.present?
          differences[:update] ||= {}

          if assoc_class == 'EmployerProfile'
            if source[:fein] != other[:fein]
              differences[:update][key || attr_val] = other
            end
          elsif assoc_class == 'Plan'
            if source[:hios_id] != other[:hios_id]
              differences[:update][key || attr_val] = other
            end
          else
            if attr_val.to_s.match(/_id$/).present?
              identifer_val = source[attr_val.to_sym] || other[attr_val.to_sym]
              key = "#{attr_val}:#{identifer_val}" if identifer_val.present?
            end

            differences[:update][key || attr_val] = compare(base_record: source, compare_record: other)
          end
        end
      end
      differences
    end


    def self.enumerated_associations
      associations = [
        {association: "plan", enumeration_field: "hios_id", cardinality: "one", enumeration: [ ]},
        {association: "hbx_enrollment_members", enumeration_field: "hbx_id", cardinality: "one", enumeration: [ ]},
        {association: "broker", enumeration_field: "npn", cardinality: "one", enumeration: [ ]}
      ]

      associations << {association: "employer_profile", enumeration_field: "fein", cardinality: "one", enumeration: [ ]} if @shop
      associations
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
          aasm_state: enrollments.first.aasm_state.camelcase,
          terminated_on: (enrollments.first.terminated_on.blank? ? nil : enrollments.first.terminated_on.strftime("%m/%d/%Y")),
        }

        if @shop && employer = enrollments.first.employer_profile
          @transcript[:employer_details] = {
            fein: employer.fein,
            legal_name:  employer.legal_name
          }
        end
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