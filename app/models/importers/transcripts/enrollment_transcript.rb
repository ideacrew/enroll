module Importers::Transcripts
  
  class StaleRecordError < StandardError; end
  class AmbiguousMatchError < StandardError; end
  class PersonMissingError < StandardError; end

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
      },
      enrollment: {
        remove: 'ignore'
      }
    }

    def process
      @updates = {}
      @people_cache = {}
      @comparison_result = ::Transcripts::ComparisonResult.new(@transcript)

      if @transcript[:source_is_new]
        create_new_enrollment
      else
        @enrollment = find_instance
        begin
          validate_update

          @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
            actions = @comparison_result.changeset_section_actions [section]

            section_rows += actions.reduce([]) do |rows, action|
              attributes = @comparison_result.changeset_content_at [section, action]
              if section != :enrollment
                rows << send(action, section, attributes)
              else
                log_ignore(action.to_sym, section, 'hbx_id')
                rows
              end
            end
          end
        rescue Exception => e
          @updates[:update_failed] = ['Merge Failed', e.to_s]
        end
      end
    end

    def validate_update
      # action section atribute value

      @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
        actions = @comparison_result.changeset_section_actions [section]
        actions.each do |action|
          attributes = @comparison_result.changeset_content_at [section, action]

          attributes.each do |attribute, value|

            if section == :base
              if action == 'update' ||  action == 'add'
                if attribute == 'effective_on'
                  if @enrollment.coverage_terminated? || @enrollment.coverage_canceled?
                    raise "Update failed. Enrollment is in #{@enrollment.aasm_state.camelcase} state."
                  end
                end
              end
            end

            if section == :plan && action == 'add'
              @plan = Plan.where(hios_id: other_enrollment.plan.hios_id, active_year: other_enrollment.plan.active_year).first
              if @plan.blank?
                raise "Plan not found with HIOS ID #{association['hios_id']} for year #{association['active_year']}."
              end
            end

            if section == :hbx_enrollment_members
              if action != 'remove'
                
                hbx_id = (action == 'add' ? value["hbx_id"] : attribute.split(':')[1])            
                enrollment_member = @other_enrollment.hbx_enrollment_members.detect{|em| em.hbx_id == hbx_id}
                matched_people = find_matching_person(enrollment_member.person)

                if matched_people.blank?
                  raise PersonMissingError, 'Hbx Enrollment member person record missing in EA.'
                end

                if matched_people.size > 1
                  raise AmbiguousMatchError, 'Hbx Enrollment member matched with multiple people in EA.'
                end
              end
            end

            if section == :enrollment
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
      if termination_date > TimeKeeper.date_of_record
        enrolllment.schedule_coverage_termination! if @enrollment.may_schedule_coverage_termination?
      else
        @enrollment.terminate_coverage! if @enrollment.may_terminate_coverage?
      end

      @enrollment.update!({:terminated_on => termination_date})
    end

    def add_plan(association)
      @plan ||= Plan.where(hios_id: association['hios_id'], active_year: association['active_year']).first
      @enrollment.update_attributes({ plan_id: @plan.id, carrier_profile_id: @plan.carrier_profile_id })
    end

    def add_hbx_enrollment_members(association)
      other_enrollment_member = @other_enrollment.hbx_enrollment_members.detect{|member| member.family_member.hbx_id == association['hbx_id']}
      matching_person = find_matching_person(other_enrollment_member.family_member.person).first

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
 
    def update_effective_on(value)
      @enrollment.update!({:effective_on => value})
    end

    def update_terminated_on(value)
      @enrollment.update!({:terminated_on => value})
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

        attributes.each do |identifier, value|
          if rule == 'edi'
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
          else
            log_ignore(:update, section, identifier)
          end
        end
      end
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

    def csv_row
      @people_cache = {}
      @plan = nil

      @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
        actions = @comparison_result.changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = @comparison_result.changeset_content_at [section, action]

          person_details = [
            @transcript[:primary_details][:hbx_id],
            @transcript[:primary_details][:ssn], 
            @transcript[:primary_details][:last_name], 
            @transcript[:primary_details][:first_name]
          ]

          fields_to_ignore = ['_id', 'updated_by']
          rows = []
          attributes.each do |attribute, value|
            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end

            plan_details = (@transcript[:plan_details].present? ? @transcript[:plan_details].values : 4.times.map{nil})
            action_taken = (@updates[:update_failed].present? ? @updates[:update_failed] : @updates[action.to_sym][section][attribute])

            if value.is_a?(Array)
              value.each do |val|
                rows << ([@transcript[:identifier]] + person_details + plan_details + [action, "#{section}:#{attribute}", val] + (action_taken || []))
              end
            else
              rows << ([@transcript[:identifier]] + person_details + plan_details + [action, "#{section}:#{attribute}", value] + (action_taken || []))
            end   
          end

          rows
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
      @updates[action] ||= {}
      @updates[action][section] ||= {}
      @updates[action][section][field] = ["Ignored", "Ignored per Enrollment update rule set."]
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

    def find_matching_person(person)
      return @people_cache[person.hbx_id] if @people_cache[person.hbx_id].present?

      if person.hbx_id.present?
        matched_people = ::Person.where(hbx_id: person.hbx_id)
      end

      if matched_people.blank?
        matched_people = ::Person.match_by_id_info(
            ssn: person.ssn,
            dob: person.dob,
            last_name: person.last_name,
            first_name: person.first_name
          )
      end

      @people_cache[person.hbx_id] = matched_people
      matched_people
    end

    def create_new_enrollment
      @updates[:new] ||= {} 
      @updates[:new][:new] ||= {} 

      begin
        primary_applicant = @other_enrollment.family.primary_applicant
        matched_people = find_matching_person(primary_applicant.person)

        if matched_people.size > 1
          raise AmbiguousMatchError, 'Found multiple people in EA with given subscriber.'
        end

        if matched_people.size == 0
          raise PersonMissingError, 'Matching person not found.'
        end

        matched_person = matched_people.first

        if matched_person.consumer_role.blank?
          raise PersonMissingError, 'Consumer role missing.'
        end

        if matched_person.families.size > 1
          raise AmbiguousMatchError, 'Found multiple families in EA for the given subscriber.'
        end

        if matched_person.families.size == 0
          raise "Families don't exist for the given subscriber in EA."
        end

        family = matched_person.families.first
        plan = @other_enrollment.plan
        ea_plan = Plan.where(hios_id: plan.hios_id, active_year: plan.active_year).first

        if ea_plan.blank?
          raise "Plan with hios_id #{plan.hios_id} not found in EA."
        end

        hbx_enrollment = family.active_household.hbx_enrollments.build({
          hbx_id: @other_enrollment.hbx_id,
          kind: @other_enrollment.kind,
          consumer_role_id: matched_person.consumer_role.id,
          elected_aptc_pct: @other_enrollment.elected_aptc_pct,
          applied_aptc_amount: @other_enrollment.applied_aptc_amount,
          coverage_kind: @other_enrollment.coverage_kind, 
          effective_on: @other_enrollment.effective_on,
          terminated_on: @other_enrollment.terminated_on,
          submitted_at: TimeKeeper.datetime_of_record,
          created_at: TimeKeeper.datetime_of_record,
          updated_at: TimeKeeper.datetime_of_record
        })

        hbx_enrollment.plan= ea_plan

        @other_enrollment.hbx_enrollment_members.each do |member| 
          matched_people = find_matching_person(member.family_member.person)
          if matched_people.size > 1
            raise AmbiguousMatchError, "Found multiple people matches for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end

          if matched_people.size == 0
            raise PersonMissingError, 'Matching person not found for #{member.family_member.person.first_name} #{member.family_member.person.last_name}.'
          end

          family_member = family.add_family_member(matched_people.first, is_primary_applicant: false)
          hbx_enrollment.hbx_enrollment_members.build({
            applicant_id: family_member.id,
            is_subscriber: member.is_subscriber,
            eligibility_date: member.coverage_start_on,
            coverage_start_on: member.coverage_start_on,
            coverage_end_on: member.coverage_end_on
          })
        end

        family.save!

        @updates[:new][:new]['hbx_id'] = ["Success", "Enrollment added successfully using EDI source"]
      rescue Exception => e
        @updates[:new][:new]['hbx_id'] = ["Failed", "#{e.inspect}"]
      end
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