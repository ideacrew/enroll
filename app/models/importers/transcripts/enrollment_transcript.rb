module Importers::Transcripts
  
  class StaleRecordError < StandardError; end
  class AmbiguousMatchError < StandardError; end
  class EnrollmentMissingError < StandardError; end

  class EnrollmentTranscript

    attr_accessor :transcript, :updates, :market, :other_enrollment

    ENUMERATION_FIELDS = {
      plan: { enumeration_field: "hios_id", enumeration: [ ]},
      hbx_enrollment_members: { enumeration_field: "hbx_id", enumeration: [ ]},
      broker: { enumeration_field: "npn", enumeration: [ ]}
    }

    SUBSCRIBER_SOURCE_RULE_MAP = {
    }

    SOURCE_RULE_MAP = {
      base: {
        add: {
          terminated_on: 'edi'
        },
        update: {
          applied_aptc_amount: 'edi',
          terminated_on: 'edi',
          coverage_kind: 'ignore',
          hbx_id: 'ignore',
          effective_on: 'edi'
        },
        remove: 'ignore'
      },
      plan: {
        add: 'edi',
        update: 'ignore',
        remove: 'ignore'
      },
      hbx_enrollment_members: {
        add: 'edi',
        update: 'edi',
        remove: 'ignore'
      },
      broker: {
        add: 'ignore',
        update: 'ignore',
        remove: 'ignore'
      }
    }

    def process
      @updates = {}
      @comparison_result = ::Transcripts::ComparisonResult.new(@transcript)

      if @transcript[:source_is_new]
        create_new_enrollment
      else
        @enrollment = find_instance
        raise EnrollmentMissingError, "Enrollment match not found!" if @enrollment.blank?

        @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
          actions = @comparison_result.changeset_section_actions [section]

          section_rows += actions.reduce([]) do |rows, action|
            attributes = @comparison_result.changeset_content_at [section, action]
            if section != :enrollment
              rows << send(action, section, attributes)
            else
              rows
            end
          end
        end
      end
    end

    def add(section, attributes)
      rule = find_rule_set(section, :add)

      @updates[:add] ||= {} 
      @updates[:add][section] ||= {}

      if section == :base
        attributes.each do |field, value|
          if rule == 'edi'
            send("add_#{field}", value)
          else
            log_ignore(:add, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]

        attributes.each do |identifier, association|
          if rule == 'edi'
            begin
              send("add_#{section}", association)
              log_success(:add, section, identifier)
            rescue Exception => e 
              @updates[:add][section][identifier] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:add, section, identifier)
          end
        end
      end
    end

    def add_terminated_on(termination_date)
      @enrollment.update!({:terminated_on => termination_date})
    end

    def add_plan(association)
      plan = Plan.where(hios_id: association['hios_id'], active_year: association['active_year']).first
      if plan.blank?
        raise "Plan not found with #{association['hios_id']} for coverage year #{association['active_year']}"
      end
      @enrollment.update_attributes({ plan_id: plan.id, carrier_profile_id: plan.carrier_profile_id })
    end

    def add_hbx_enrollment_members(association)
      other_enrollment_member = @other_enrollment.hbx_enrollment_members.detect{|member| member.family_member.hbx_id == association['hbx_id']}
      matched_people = find_matching_person(other_enrollment_member.family_member.person)

      if matched_people.blank?
        raise 'Unable to match person in EA'
      end

      if matched_people.size > 1
        raise 'Matched multiple people in EA'
      end

      matching_person = matched_people.first

      family = @enrollment.family
      family_member = family.add_family_member(matching_person, is_primary_applicant: false)

      @enrollment.hbx_enrollment_members.build({
        applicant_id: family_member.id,
        is_subscriber: other_enrollment_member.is_subscriber,
        eligibility_date: other_enrollment_member.coverage_start_on,
        coverage_start_on: other_enrollment_member.coverage_start_on,
        coverage_end_on: other_enrollment_member.coverage_end_on
      })

      family.save!
    end

    def find_matching_person(person)
      ::Person.match_by_id_info(
        ssn: person.ssn,
        dob: person.dob,
        last_name: person.last_name,
        first_name: person.first_name
      )
    end

    def update_effective_on(value)
      if @enrollment.coverage_terminated? || @enrollment.coverage_canceled?
        raise "Update failed. Enrollment is in #{@enrollment.aasm_state.camelcase} state."
      end
      @enrollment.update!({:effective_on => value})
    end

    def update_applied_aptc_amount(value)
      @enrollment.update!({:applied_aptc_amount => value})
    end

    def update(section, attributes)
      rule = find_rule_set(section, :update)

      @updates[:update] ||= {} 
      @updates[:update][section] ||= {} 

      if section == :base
        attributes.each do |field, value|
          if value.present? && (rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi'))
            begin
              # validate_timestamp(section)
              send("update_#{field}", value)
              log_success(:update, section, field)
            rescue Exception => e
              @updates[:update][section][field] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:update, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]

        if rule == 'edi'
          attributes.each do |identifier, value|            
            value.each do |key, v|
              if (key == 'add' || key == 'update') && section == :hbx_enrollment_members
                begin
                  member_hbx_id = identifier.split(':')[1]
                  member = @enrollment.hbx_enrollment_members.detect{|e| e.family_member.hbx_id == member_hbx_id}
                  if member.blank?
                    raise "Family member with hbx id #{member_hbx_id} missing."
                  end
                  member.update_attributes(v)
                  log_success(:update, section, identifier)
                rescue Exception => e
                  @updates[:update][section][field] = ["Failed", "#{e.inspect}"]
                end
              else
                log_ignore(:update, section, identifier)
              end
            end
          end
        else
          log_ignore(:update, section, identifier)
        end
      end
    end

    def remove_terminated_on
      if @enrollment.coverage_terminated? || @enrollment.coverage_termination_pending?
        raise "Remove failed. Enrollment is in #{@enrollment.aasm_state.camelcase} state."
      end
      @enrollment.update!({:effective_on => nil})
    end

    def remove(section, attributes)
      rule = find_rule_set(section, :remove)

      @updates[:remove] ||= {} 
      @updates[:remove][section] ||= {} 

      if section == :base
        attributes.each do |field, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi')
          else
            log_ignore(:remove, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]
        attributes.each do |identifier, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[identifier.to_sym] == 'edi')
          else
            log_ignore(:remove, section, identifier)
          end
        end
      end
    end

    private

    def log_success(action, section, field)
      kind = (section == :base ? 'attribute' : 'record')
      @updates[action][section][field] = case action
      when :add
        ["Success", "Added #{field} #{kind} on #{section} using EDI source"]
      when :update
        ["Success", "Updated #{field} #{kind} on #{section} using EDI source"]
      else
        ["Success", "Removed #{field} on #{section}"]
      end
    end

    def log_ignore(action, section, field)
      @updates[action][section][field] = ["Ignored", "Ignored per Family update rule set."]
    end

    def find_rule_set(section, action)
      if @market == 'shop'
        SUBSCRIBER_SOURCE_RULE_MAP[section][action]
      else
        SOURCE_RULE_MAP[section][action]
      end
    end

    def find_instance
      ::HbxEnrollment.find(@transcript[:source]['_id'])
    end

    def create_new_enrollment

    end

    def validate_timestamp(section)
      if section == :base
        if @enrollment.updated_at.to_date > @transcript[:source]['updated_at'].to_date
          raise StaleRecordError, "Change set unprocessed, source record updated after Transcript generated. Updated on #{@enrollment.updated_at.strftime('%m/%d/%Y')}"
        end
      else
        transcript_record = @transcript[:source][section.to_s].sort_by{|x| x['updated_at']}.reverse.first if @transcript[:source][section.to_s].present?
        source_record = @enrollment.send(section).sort_by{|x| x.updated_at}.reverse.first if @enrollment.send(section).present?
        return if transcript_record.blank? || source_record.blank?

        if source_record.updated_at.to_date > transcript_record['updated_at'].to_date
          raise StaleRecordError, "Change set unprocessed, source record updated after Transcript generated. Updated on #{source_record.updated_at.strftime('%m/%d/%Y')}"
        end
      end
    end
  end
end