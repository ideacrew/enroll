module Employers::EmployerProfileHelper
 def show_oop_pdf_link(aasm_state)
  ["enrolling" ,"published", "enrolled"," active","renewing_published", "renewing_enrolling", "renewing_enrolled"].include?(aasm_state)
  end
end