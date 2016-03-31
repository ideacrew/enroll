class NoticeTriggerElementGroup
  include Mongoid::Document
  include Mongoid::Timestamps

   MARKET_KINDS = %w(individual shop)
   RECIPIENT_KINDS = %w(employer, employee, former_employee, employee_dependents broker hbx_admin hbx_staff csr case_worker)
   DELIVERY_METHOD_KINDS = %w(email paper)

   field :title, type: String
   field :trigger_event, type: String
   field :primary_recipients, type: Array, default: []
   field :secondary_recipients, type: Array, default: []
   field :primary_recipient_delivery_method, type: Array, default: []
   field :secondary_recipient_delivery_method, type: Array, default: []



end
