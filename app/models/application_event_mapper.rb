class ApplicationEventMapper
  Resource = Struct.new(:resource_name, :identifier_method, :identifier_key)

  EVENT_MAP = {
      employer: {
          binder_paid: :benefit_coverage_initial_binder_paid,        
        }
    }

  RESOURCE_MAP = {
    employer_profile: Resource.new(:employer, :hbx_id, :employer_id)
  }

  class << self
    def publish_friendly_event(resource_name, current_event, from_state, to_state)
    end

    def map_resource(resource_name)
      RESOURCE_MAP[resource_name.to_s.underscore.to_sym]
    end

    def map_event_name(resource_mapping, transition_event_name)
      event_name = transition_event_name.to_s.sub(/\!$/, '').to_sym
      if EVENT_MAP[resource_mapping.resource_name][event_name].present?
        event_name = EVENT_MAP[resource_mapping.resource_name][event_name]
      end
      "acapi.info.events.employer.#{event_name}"
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
