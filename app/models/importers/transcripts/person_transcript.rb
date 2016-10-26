module Importers::Transcripts
  
  class PersonError < StandardError; end

  class PersonTranscript

    attr_accessor :transcript, :updates, :market

    # SUBSCRIBER_SOURCE_RULE_MAP = {
    #   add: {
    #     base: 'edi',
    #     addresses: 'edi',
    #     phones: 'edi',
    #     emails: 'edi'
    #   },
    #   update: {
    #     base: {
    #       edi: ['first_name', 'middle_name', 'last_name', 'name_suffix'],
    #       ea: ['gender', 'dob', 'ssn']
    #     },
    #     addresses: 'edi',
    #     phones: 'edi',
    #     emails: 'edi'
    #   },
    #   remove: {
    #     base: {
    #       ignore: ['is_incarcerated', 'no_dc_address', 'no_dc_address_reason']
    #     }
    #   }
    # }

   #    ADD_RULE_SET = {
   #   base: 'edi',
   #   phones: 'edi',
   #   addresses: 'edi',
   #   emails: 'edi'
   # }

   # UPDATE_RULE_SET = {
   #   base: 'edi',
   #   phones: 'edi',
   #   addresses: 'edi',
   #   emails: 'edi'
   # }

   # REMOVE_RULE_SET = {
   #  base: {
   #    middle_name: 'edi',
   #    no_dc_address: 'ignore',
   #    no_dc_address_reason: 'ignore'
   #    },
   #    phones: {
   #      fax: 'edi'
   #    }
   #  }

    # DEPENDENT_SOURCE_RULE_MAP = {
    #   add: {
    #     base: {
    #       ea: ['middle_name'],
    #       edi: ['all']
    #     },
    #     addresses: 'edi',
    #     phones: 'edi',
    #     emails: 'edi'
    #   },
    #   update: {
    #     base: {
    #       ea: ['first_name', 'middle_name', 'last_name', 'name_suffix'],
    #       edi: ['gender', 'dob', 'ssn']
    #     },
    #     addresses: 'edi',
    #     phones: 'edi',
    #     emails: 'edi'
    #   },
    #   remove: {
    #     base: {
    #       ignore: ['is_incarcerated', 'no_dc_address', 'no_dc_address_reason'],
    #     }
    #   }
    # }


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

    def initialize
      @updates = {}
    end

    def process
      compare = Transcripts::ComparisonResult.new(@transcript)

      if @transcript[:source_is_new]
        create_new_person_record
      else
        @person = find_instance

        compare.changeset_sections.reduce([]) do |section_rows, section|
          actions = compare.changeset_section_actions [section]

          section_rows += actions.reduce([]) do |rows, action|
            attributes = compare.changeset_content_at [section, action]

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
              @person.send("#{field}=", value)
              log_success(:add, section, field)
            rescue Exception => e
              @updates[:add][section][field] = "Failed: #{e.inspect}"
            end
          else
            log_ignore(:add, section, field)
          end
        end
      else
        attributes.each do |identifier, association|
          if rule == 'edi'
            begin
              validate_timestamp(section)

              if match = @person.send(section).detect{|assoc| assoc.send(enumerated_association[:enumeration_field]) == identifier}
                raise "record already created on #{match.updated_at.strftime('%m/%d/%Y')}"
              end

              @person.send(section).build(association)
              log_success(:add, section, identifier)
            rescue Exception => e 
              @updates[:add][section][identifier] = "Failed: #{e.inspect}"
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
          if rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi')
            begin
              validate_timestamp(section)
              @person.send("#{field}=", value)
              log_success(:update, section, field)
            rescue Exception => e
              @updates[:update][section][field] = "Failed: #{e.inspect}"
            end
          else
            log_ignore(:update, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]
        
        attributes.each do |identifier, value|
          if rule == 'edi'
            association = @person.send(section).detect{|assoc| assoc.send(enumerated_association[:enumeration_field]) == identifier}
            association.assign_attributes(value['update'])
            log_success(:update, section, identifier)
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
              @person.send("#{field}=", nil)
              log_success(:remove, section, field)
            rescue Exception => e
              @updates[:remove][section][field] = "Failed: #{e.inspect}"
            end
          else
            log_ignore(:remove, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]
        attributes.each do |identifier, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[identifier.to_sym] == 'edi')
            association = @person.send(section).detect{|assoc| assoc.send(enumerated_association[:enumeration_field]) == identifier}
            association.delete
            log_success(:remove, section, identifier)
          end
        end
      end
    end

    private

    def log_success(action, section, field)
      @updates[action][section][field] = case action
      when :add
        "Success: Added #{field} on #{section} with EDI source"
      when :update
        "Success: Updated #{field} on #{section} with EDI source"
      else
        "Success: Removed #{field} on #{section}"
      end
    end

    def log_ignore(action, section, field)
      @updates[action][section][field] = "Ignored"
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

    def create_new_person_record
      @updates[:new] ||= {}
      @updates[:new][:new] ||= {}

      begin
        Person.new(@transcript[:other]).save!
        @updates[:new][:new][:ssn] = "Success: Created new person record"
      rescue Exception => e 
        @updates[:new][:new][:ssn] = "Failed: #{e.inspect}"
      end
    end

    def validate_timestamp(section)
      if section == :base
        if @person.updated_at >= @transcript[:source]['updated_at'].to_date
          raise "Person base record got updated on #{@person.updated_at.strftime('%m/%d/%Y')}"
        end
      else
        transcript_record = @transcript[:source][section.to_s].sort_by{|x| x['updated_at']}.reverse.first
        source_record = @person.send(section).sort_by{|x| x.updated_at}.reverse.first
        return if transcript_record.blank? || source_record.blank?

        if source_record.updated_at.to_date >= transcript_record['updated_at'].to_date
          raise "Person #{section} got updated on #{source_record.updated_at.strftime('%m/%d/%Y')}"
        end
      end
    end
  end
end
