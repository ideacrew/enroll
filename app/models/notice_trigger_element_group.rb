class NoticeTriggerElementGroup
  include Mongoid::Document

  embedded_in :notice_trigger

  RECIPIENT_KINDS = %w(employer employee former_employee, employee_dependents broker hbx_admin hbx_staff csr case_worker)
  DELIVERY_METHOD_KINDS = %w(secure_message email paper)
  MARKET_PLACE_KINDS  = %w(individual shop)


  field :market_places,                       type: Array, default: ["any"]
  field :primary_recipients,                  type: Array, default: ["any"]
  field :primary_recipient_delivery_method,   type: Array, default: ["paper"]
  field :secondary_recipients,                type: Array, default: ["any"]
  field :secondary_recipient_delivery_method, type: Array, default: ["paper"]

end
