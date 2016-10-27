module Importers::Transcripts
  
  class StaleRecordError < StandardError; end

  class PersonTranscript

    attr_accessor :transcript, :updates, :market


    ENUMERATION_FIELDS = {
      addresses: { enumeration_field: "kind", enumeration: ["home", "work", "mailing", "primary"] },
      phones: { enumeration_field: "kind", enumeration: Phone::KINDS },
      emails: { enumeration_field: "kind", enumeration: Email::KINDS },
    }

    SUBSCRIBER_SOURCE_RULE_MAP = {
      base: {
        add: 'edi',
        update: {
          first_name: 'edi',
          middle_name: 'edi', 
          last_name: 'edi',
          name_suffix: 'edi',
          gender: 'ea',
          dob: 'ea',
          ssn: 'ea'
        },
        remove: {
          middle_name: 'edi'
        }
      },
      addresses: {
        add: 'edi',
        update: 'edi',
        remove: 'ea'
      },
      phones: {
        add: 'edi',
        update: 'edi',
        remove: {
          kind: { fax: 'edi'}
        }
      },
      emails: {
        add: 'edi',
        update: 'edi',
        remove: 'ea'
      }
    }


    SOURCE_RULE_MAP = {
      base: {
        add: 'edi',
        update: 'edi',
        remove: {
          no_dc_address: 'ignore',
          no_dc_address_reason: 'ignore',
          middle_name: 'edi'
        }
      },
      addresses: {
        add: 'edi',
        update: 'edi',
        remove: 'ignore'
      },
      phones: {
        add: 'edi',
        update: 'edi',
        remove: {
          fax: 'edi'
        }
      },
      emails: {
        add: 'edi',
        update: 'edi',
        remove: 'ignore'
      }
    }

    def process
      @updates = {}
      @comparison_result = ::Transcripts::ComparisonResult.new(@transcript)

      if @transcript[:source_is_new]
        create_new_person_record
      else
        @person = find_instance

        @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
          actions = @comparison_result.changeset_section_actions [section]

          section_rows += actions.reduce([]) do |rows, action|
            attributes = @comparison_result.changeset_content_at [section, action]

            rows << send(action, section, attributes)
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
            begin
              validate_timestamp(section)
              @person.update!({field => value})
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
              validate_timestamp(section)
              if match = @person.send(section).detect{|assoc| assoc.send(enumerated_association[:enumeration_field]) == identifier}
                raise "record already created on #{match.updated_at.strftime('%m/%d/%Y')}"
              end
              @person.send(section).create(association)
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

    def update(section, attributes)
      rule = find_rule_set(section, :update)

      @updates[:update] ||= {} 
      @updates[:update][section] ||= {} 

      if section == :base
        attributes.each do |field, value|
          if value.present? && (rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi'))
            begin
              validate_timestamp(section)
              @person.update!({field => value})
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
              begin
                validate_timestamp(section)
                association = @person.send(section).detect{|assoc| assoc.send(enumerated_association[:enumeration_field]) == identifier}
                if association.blank?
                  raise "#{section} #{identifier} record missing!"
                end

                if key == 'add' || key == 'update'
                  association.update_attributes(v)
                elsif key == 'remove'
                  v.each do |field, val|
                    association.update!({field => nil})
                  end
                end

                log_success(:update, section, identifier)
              rescue Exception => e
                @updates[:update][section][identifier] = ["Failed", "#{e.inspect}"]
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
          if rule[field.to_sym] == 'edi'
            begin
              validate_timestamp(section)
              @person.update!({field => nil})
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
              validate_timestamp(section)
              association = @person.send(section).detect{|assoc| assoc.send(enumerated_association[:enumeration_field]) == identifier}
              association.delete
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

      @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
        actions = @comparison_result.changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = @comparison_result.changeset_content_at [section, action]

          if @transcript[:source_is_new]
            person_details = [@transcript[:other]['hbx_id'], Person.decrypt_ssn(@transcript[:other]['encrypted_ssn']), @transcript[:other]['last_name'], @transcript[:other]['first_name']]
          else
            person_details = [@transcript[:source]['hbx_id'], Person.decrypt_ssn(@transcript[:source]['encrypted_ssn']), @transcript[:source]['last_name'], @transcript[:source]['first_name']]
          end

          fields_to_ignore = ['_id', 'updated_by']

          rows += attributes.collect do |attribute, value|
            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end
            (person_details + [action, "#{section}:#{attribute}", value] + (@updates[action.to_sym][section][attribute] || []))
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
      @updates[action][section][field] = ["Ignored", "Ignored per Person update rule set."]
    end

    def find_rule_set(section, action)
      if @market == 'shop'
        SUBSCRIBER_SOURCE_RULE_MAP[section][action]
      else
        SOURCE_RULE_MAP[section][action]
      end
    end

    def find_instance
      Person.find(@transcript[:source]['_id'])
    end

    def match_person
      ::Person.match_by_id_info(
        ssn: @transcript[:other]['ssn'],
        dob: @transcript[:other]['dob'],
        last_name: @transcript[:other]['last_name'],
        first_name: @transcript[:other]['first_name']
        ).first
    end

    def create_new_person_record
      @updates[:new] ||= {}
      @updates[:new][:new] ||= {}

      begin
        if match_person.blank?
          Person.new(@transcript[:other]).save!
          @updates[:new][:new]['ssn'] = ["Success", "Created new person record"]
        else
          raise StaleRecordError, "Person recrod created on #{match_person.created_at.strftime('%m/%d/%Y')} after transcript generated"
        end
      rescue Exception => e 
        @updates[:new][:new]['ssn'] = ["Failed", "#{e.inspect}"]
      end
    end

    def validate_timestamp(section)
      if section == :base
        if @person.updated_at.to_date > @transcript[:source]['updated_at'].to_date
          raise StaleRecordError, "Change set unprocessed, source record updated after Transcript generated. Updated on #{@person.updated_at.strftime('%m/%d/%Y')}"
        end
      else
        transcript_record = @transcript[:source][section.to_s].sort_by{|x| x['updated_at']}.reverse.first if @transcript[:source][section.to_s].present?
        source_record = @person.send(section).sort_by{|x| x.updated_at}.reverse.first if @person.send(section).present?
        return if transcript_record.blank? || source_record.blank?

        if source_record.updated_at.to_date > transcript_record['updated_at'].to_date
          raise StaleRecordError, "Change set unprocessed, source record updated after Transcript generated. Updated on #{source_record.updated_at.strftime('%m/%d/%Y')}"
        end
      end
    end
  end
end
