class NoticeTriggerElementGroup
  include Mongoid::Document

  embedded_in :notice_trigger

  MARKET_KINDS = %w(individual shop)
  RESOURCE_KINDS = %w(family employer_profile employee_role consumer_role broker_agency broker_role )
  RECIPIENT_KINDS = %w(employer employee former_employee, employee_dependents broker hbx_admin hbx_staff csr case_worker)
  DELIVERY_METHOD_KINDS = %w(secure_message email paper)

  field :market_places,                       type: Array, default: ["any"]   # %w[any shop individual],
  field :primary_recipients,                  type: Array, default: ["any"]
  field :secondary_recipients,                type: Array, default: ["any"]
  field :primary_recipient_delivery_method,   type: Array, default: ["paper"]
  field :secondary_recipient_delivery_method, type: Array, default: ["paper"]

end

class NoticeTriggerSetup
  employer_profile = EmployerProfile.all.first

  employer_conversion_notice_trigger = NoticeTrigger.new(
    title: "Employer Conversion Notice",
    resource_kind: "employer_resource_listener",
    event_id: "conversion_employer_transferred_to_hbx",  # trigger event
    template_id: "shop_14",                              # reference to notice template
    market_places: "shop",
    employer_profile: employer_profile,

    notice_trigger_element_group: NoticeTriggerElementGroup.new(
        primary_recipients: ["employer"],
        primary_recipient_delivery_method: ["paper"],
        secondary_recipients: ["employer"],
        secondary_recipient_delivery_method: ["email"],
      )
    )

  employer_conversion_notice_trigger
end
