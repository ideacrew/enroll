class ApplicationEventMapper
  Resource = Struct.new(:resource_name, :identifier_method, :identifier_key, :search_method)
  ResourceReverseLookup = Struct.new(:mapped_class, :identifier_key, :search_method)

  EVENT_PREFIX = "acapi.info.events."

  EVENT_MAP = {
      employer: {
          binder_paid: :benefit_coverage_initial_binder_paid,        
        }
    }

  RESOURCE_MAP = {
    "EmployerProfile" => Resource.new(:employer, :hbx_id, :employer_id, :by_hbx_id)
  }

  REVERSE_LOOKUP_MAP = RESOURCE_MAP.inject({}) do |acc, vals|
    key, mapping = vals
    acc[mapping.resource_name.to_s] = ResourceReverseLookup.new(key.constantize, mapping.identifier_key.to_s, mapping.search_method)
    acc
  end

  def self.extract_event_parts(event_name)
    event_parts = event_name.split(".")
    [event_parts[3], event_parts[4]]
  end

  def self.lookup_resource_mapping(event_name)
    resource_name, *garbage_i_dont_care_about = extract_event_parts(event_name)
    return REVERSE_LOOKUP_MAP[resource_name] if REVERSE_LOOKUP_MAP.has_key?(resource_name)
    ResourceReverseLookup.new(resource_name.camelize.constantize, "#{resource_name}_id", :find) rescue nil
  end

  class << self
    def map_resource(resource_name)
      mapped_name = resource_name.to_s.underscore.to_sym
      return RESOURCE_MAP[resource_name.to_s] if RESOURCE_MAP.has_key?(resource_name.to_s)
      Resource.new(mapped_name, :id, (mapped_name.to_s + "_id").to_sym)
    end

    def map_event_name(resource_mapping, transition_event_name)
      event_name = transition_event_name.to_s.sub(/\!$/, '').to_sym
      resource_prefix = EVENT_PREFIX + "#{resource_mapping.resource_name}."
      if EVENT_MAP[resource_mapping.resource_name] && EVENT_MAP[resource_mapping.resource_name][event_name]
        event_name = EVENT_MAP[resource_mapping.resource_name][event_name]
      end
      resource_prefix + event_name.to_s
    end
  end
end


#   EVENT_MAP = {
#       employer_profile: {
#           applicant: :created,
# # - address_changed
# # - contact_changed
# # - fein_corrected
# # - name_changed
# # - broker_added
# # - broker_terminated          
#         },
#       plan_year: {
#           published:  :benefit_coverage_initial_application_approved,
#           enrolling:  :benefit_coverage_initial_open_enrollment_began,
#           enrolled:   :benefit_coverage_initial_open_enrollment_ended,
#           draft:      :benefit_coverage_initial_application_reverted,
#           renewing_draft:       :benefit_coverage_renewal_application_period_begin,
#           renewing_published:   :benefit_coverage_renewal_application_approved,
#           renewing_enrolling:   :benefit_coverage_renewal_open_enrollment_began,
#           renewing_enrolled:    :benefit_coverage_renewal_open_enrollment_ended,
# # benefit_coverage_renewal_application_reverted
#           active: :benefit_coverage_period_begin,
#           suspended:  :benefit_coverage_period_suspended,
#           terminated: :benefit_coverage_period_terminated,
#           expired:    :benefit_coverage_period_expired,
#         }
#     }


      # <xs:enumeration value="urn:openhbx:events:v1:employer#created"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#address_changed"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#contact_changed"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#fein_corrected"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#name_changed"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#broker_added"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#broker_terminated"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#general_agent_added"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#general_agent_terminated"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_initial_open_enrollment_ended"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_initial_binder_paid"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_initial_application_approved"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_period_terminated_voluntary"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_period_terminated_nonpayment"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_period_terminated_relocated"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_renewal_open_enrollment_ended"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_renewal_terminated_voluntary"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_renewal_terminated_ineligible"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#benefit_coverage_period_expired"/>
      # <xs:enumeration value="urn:openhbx:events:v1:employer#other"/>
