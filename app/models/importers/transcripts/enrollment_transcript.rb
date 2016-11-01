module Importers::Transcripts
  
  class StaleRecordError < StandardError; end
  class AmbiguousMatchError < StandardError; end
  class PersonMissingError < StandardError; end

  class EnrollmentTranscript

    attr_accessor :transcript, :updates, :market, :other_enrollment
    include ::Transcripts::EnrollmentCommon

    ENUMERATION_FIELDS = {
      plan: { enumeration_field: "hios_id", enumeration: [ ]},
      hbx_enrollment_members: { enumeration_field: "hbx_id", enumeration: [ ]},
      broker: { enumeration_field: "npn", enumeration: [ ]}
    }

    SOURCE_RULE_MAP = {
      base: {
        add: {
          terminated_on: 'edi'
        },
        update: {
          applied_aptc_amount: 'ignore',
          terminated_on: 'edi',
          coverage_kind: 'ignore',
          hbx_id: 'edi',
          effective_on: 'edi'
        },
        remove: {
          terminated_on: 'edi'
        }
      },
      plan: {
        add: 'ignore',
        update: 'ignore',
        remove: 'ignore'
      },
      hbx_enrollment_members: {
        add: 'ignore',
        update: 'edi',
        remove: {
          hbx_id: 'edi'
        }
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

    def fix_enrollment_coverage_start
     @other_enrollment.hbx_enrollment_members = @other_enrollment.hbx_enrollment_members.reject{|member| member.coverage_end_on.present? && !member.is_subscriber}

      if @other_enrollment.hbx_enrollment_members.any?{|member| member.coverage_end_on.blank?}

        maximum_end_date = @other_enrollment.hbx_enrollment_members.select{|m| m.coverage_end_on.present?}.sort_by{|member| member.coverage_end_on}.reverse.try(:first).try(:coverage_end_on)
        maximum_start_date = @other_enrollment.hbx_enrollment_members.sort_by{|member| member.coverage_start_on}.reverse.first.coverage_start_on

        if maximum_end_date.present?
          @other_enrollment.effective_on = [maximum_start_date, (maximum_end_date + 1.day)].max
        else
          @other_enrollment.effective_on = maximum_start_date
        end

        @other_enrollment.hbx_enrollment_members.each do |member| 
          member.coverage_start_on = @other_enrollment.effective_on
        end
      end
    end

    def process
      fix_enrollment_coverage_start
      @updates = {}
      @comparison_result = ::Transcripts::ComparisonResult.new(@transcript)

      if @transcript[:source_is_new]
        if valid_new_request
          create_new_enrollment
        end
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
                if action == 'remove'
                  @updates[:remove] ||={}
                  @updates[:remove][:enrollment] ||={}
                  send("process_enrollment_#{action}", attributes)
                else
                  log_ignore(action.to_sym, section, 'hbx_id')
                end
                rows
              end
            end
          end
        rescue Exception => e
          @updates[:update_failed] = ['Merge Failed', e.to_s]
        end
      end
    end

    def process_enrollment_remove(attributes)
      family = @enrollment.family
      enrollments = attributes['hbx_id']
      enrollments.each do |enrollment_hash|
        enrollment = family.active_household.hbx_enrollments.where(:hbx_id => enrollment_hash['hbx_id']).first
        if enrollment.effective_on == @enrollment.effective_on &&  enrollment.effective_on >= enrollment.terminated_on
          enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
           @updates[:remove][:enrollment]['hbx_id'] = ["Success", "Enrollment canceled successfully"]
        else
          enrollment.terminate_coverage! if enrollment.may_terminate_coverage?
          @updates[:remove][:enrollment]['hbx_id'] = ["Success", "Enrollment terminated successfully"]
        end
      end
    end

    def find_exact_enrollment_matches(enrollments)
      enrollment_hbx_ids = @enrollment.hbx_enrollment_members.map(&:hbx_id)

      enrollments.reject! do |en|
        en_hbx_ids = en.hbx_enrollment_members.map(&:hbx_id)
        en_hbx_ids.any?{|z| !enrollment_hbx_ids.include?(z)} || enrollment_hbx_ids.any?{|z| !en_hbx_ids.include?(z)}
      end

      enrollments.reject!{|en| (en.plan_id != @enrollment.plan_id)}
      enrollments.reject!{|en| (en.effective_on != @enrollment.effective_on)}
      enrollments
    end

    def valid_new_request
      begin
        @other_enrollment.hbx_enrollment_members.each do |member| 
          matched_people = match_person_instance(member.family_member.person)

          if matched_people.size > 1
            raise AmbiguousMatchError, "Found multiple people matches for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end

          if matched_people.size == 0
            raise PersonMissingError, "Matching person not found for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end
        end

        true
      rescue Exception => e
        @updates[:update_failed] = ['Merge Failed', e.to_s]
        return false
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
              if action == 'update'
                if attribute == 'effective_on'
                  if @enrollment.coverage_terminated? || @enrollment.coverage_canceled?
                    raise "Update failed. Enrollment is in #{@enrollment.aasm_state.camelcase} state."
                  end
                end
              elsif action == 'add'
                # if attribute == 'terminated_on'
                #   enrollments = (@market == 'shop' ? matching_shop_coverages(@enrollment) : matching_ivl_coverages(@enrollment))
                #   enrollments.reject!{|e| e == @enrollment}

                #   @exact_enrollment_matches = find_exact_enrollment_matches(enrollments)
                #   other_coverages = enrollments - @exact_enrollment_matches

                #   if other_coverages.any?
                #     message = "Enrollment can't be termed."
                #     message += "Found other active coverages #{other_coverages.map(&:hbx_id).join(',')}."
                #     message += "Found duplicate coverages #{@exact_enrollment_matches.map(&:hbx_id).join(',')}." if @exact_enrollment_matches.any?
                #     raise message
                #   end
                # end
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
                matched_people = match_person_instance(enrollment_member.person)

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
          if rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi')
            begin
              send("add_#{field}", value)
              log_success(:add, section, field)
            rescue Exception => e
              @updates[:add][section][field] = ["Failed", "#{e.inspect}"]
            end
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
        @enrollment.schedule_coverage_termination! if @enrollment.may_schedule_coverage_termination?
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
      matching_person = match_person_instance(other_enrollment_member.family_member.person).first

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

      if value > TimeKeeper.date_of_record
        @enrollment.schedule_coverage_termination! if @enrollment.may_schedule_coverage_termination?
      else
        @enrollment.terminate_coverage! if @enrollment.may_terminate_coverage?
      end
    end

    def remove_terminated_on(value)
      @enrollment.update!({:terminated_on => nil})
      @enrollment.update!({:aasm_state => 'coverage_selected'})

      @enrollment.hbx_enrollment_members.each do |member|
        member.update!({coverage_end_on: nil})
      end
    end

    def update_hbx_id(hbx_id)
      if HbxEnrollment.by_hbx_id(hbx_id).blank?
        @enrollment.update!({:hbx_id => hbx_id})
      else
        @updates[:update][:base]['hbx_id'] = ["Success", "Add EDI DB foreign key #{@enrollment.hbx_id}"]
      end
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
              log_success(:update, section, field) if @updates[:update][section][field].blank?
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
                  member = @enrollment.hbx_enrollment_members.detect{|e| e.hbx_id == member_hbx_id}
                  if member.blank?
                    raise "Family member with hbx id #{member_hbx_id} missing."
                  end
                  member.update_attributes(v)
                  log_success(:update, section, identifier)
                rescue Exception => e
                  @updates[:update][section][identifier] = ["Failed", "#{e.inspect}"]
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

    def hbx_enrollment_members_hbx_id_remove(value)
      family = @enrollment.family

      hbx_enrollment = family.active_household.hbx_enrollments.build({
        kind: @enrollment.kind,
        consumer_role_id: @enrollment.consumer_role.id,
        elected_aptc_pct: @enrollment.elected_aptc_pct,
        applied_aptc_amount: @enrollment.applied_aptc_amount,
        coverage_kind: @enrollment.coverage_kind,
        effective_on: @other_enrollment.effective_on,
        submitted_at: TimeKeeper.datetime_of_record,
        created_at: TimeKeeper.datetime_of_record,
        updated_at: TimeKeeper.datetime_of_record
      })

      hbx_enrollment.plan= @enrollment.plan
      hbx_enrollment.hbx_enrollment_members.each do |member| 
        next if member.hbx_id == value['hbx_id']
        hbx_enrollment.hbx_enrollment_members.build(member.attributes.except('_id'))
      end

      hbx_enrollment.save!
    end

    def remove(section, attributes)
      rule = find_rule_set(section, :remove)

      @updates[:remove] ||= {} 
      @updates[:remove][section] ||= {} 

      if section == :base
        attributes.each do |field, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi')
            begin
              send("remove_#{field}", value)
              log_success(:remove, section, field)
            rescue Exception => e
              @updates[:remove][section][field] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:remove, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]
        attributes.each do |identifier, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[identifier.to_sym] == 'edi')
            begin
              send("#{section}_#{identifier}_remove", value)
              log_success(:remove, section, identifier)
            rescue Exception => e
              @updates[:remove][section][identifier] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:remove, section, identifier)
          end
        end
      end
    end

    def csv_row
      @people_cache = {}
      @plan = nil

      plan_details = (@transcript[:plan_details].present? ? @transcript[:plan_details].values : 4.times.map{nil})
      person_details = [
        @transcript[:primary_details][:hbx_id],
        @transcript[:primary_details][:ssn], 
        @transcript[:primary_details][:last_name], 
        @transcript[:primary_details][:first_name]
      ]

      results = @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
        actions = @comparison_result.changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = @comparison_result.changeset_content_at [section, action]

          fields_to_ignore = ['_id', 'updated_by']
          rows = []
          attributes.each do |attribute, value|
            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end

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

      if results.empty?
        ([[@transcript[:identifier]] + person_details + plan_details + ['update']])
      else
        results
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
      SOURCE_RULE_MAP[section][action]
    end

    def find_instance
      ::HbxEnrollment.find(@transcript[:source]['_id'])
    end

    def create_new_enrollment
      @updates[:new] ||= {} 
      @updates[:new][:new] ||= {} 

      begin
        subscriber = @other_enrollment.family.primary_applicant
        matched_people = match_person_instance(subscriber.person)

        if matched_people.size > 1
          raise AmbiguousMatchError, 'Found multiple people in EA with given subscriber.'
        end

        if matched_people.size == 0
          raise PersonMissingError, 'Matching person not found.'
        end

        matched_person = matched_people.first
        families = Family.find_all_by_person(matched_person)

        if families.empty?
          if matched_person.age_on(@other_enrollment.effective_on) < 18
            raise 'Unknown primary member -- subscriber is < 18 years old'
          end

          role = Factories::EnrollmentFactory.build_consumer_role(matched_person, false)
          if matched_person.save
            role.save
            matched_person.reload
            family = matched_person.primary_family
          else
            raise "unable to update person"
          end
        else
          family = families.first
        end

        plan = @other_enrollment.plan

        ea_plan = Plan.where(hios_id: plan.hios_id, active_year: plan.active_year).first
        if ea_plan.blank?
          raise "Plan with hios_id #{plan.hios_id} not found in EA."
        end

        hbx_id = HbxEnrollment.by_hbx_id(@other_enrollment.hbx_id).present? ? nil : @other_enrollment.hbx_id

        hbx_enrollment = family.active_household.hbx_enrollments.build({
          hbx_id: hbx_id,
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
          matched_people = match_person_instance(member.family_member.person)

          if matched_people.size > 1
            raise AmbiguousMatchError, "Found multiple people matches for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end

          if matched_people.size == 0
            raise PersonMissingError, "Matching person not found for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end

          matched_person = matched_people.first

          if matched_person.consumer_role.blank?
            consumer_role = person.build_consumer_role(ssn: matched_person.ssn,
             dob: matched_person.dob,
             gender: matched_person.gender,
             is_incarcerated: matched_person.is_incarcerated,
             is_applicant: matched_person.is_applicant,
             )

            if person.save
              consumer_role.save
            else
              raise "unable to update person"
            end
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

    # def validate_timestamp(section)
    #   if section == :base
    #     if @enrollment.updated_at.to_date > @transcript[:source]['updated_at'].to_date
    #       raise StaleRecordError, "Change set unprocessed, source record updated after Transcript generated. Updated on #{@enrollment.updated_at.strftime('%m/%d/%Y')}"
    #     end
    #   else
    #     transcript_record = @transcript[:source][section.to_s].sort_by{|x| x['updated_at']}.reverse.first if @transcript[:source][section.to_s].present?
    #     source_record = @enrollment.send(section).sort_by{|x| x.updated_at}.reverse.first if @enrollment.send(section).present?
    #     return if transcript_record.blank? || source_record.blank?
    #     if source_record.updated_at.to_date > transcript_record['updated_at'].to_date
    #       raise StaleRecordError, "Change set unprocessed, source record updated after Transcript generated. Updated on #{source_record.updated_at.strftime('%m/%d/%Y')}"
    #     end
    #   end
    # end

  end
end