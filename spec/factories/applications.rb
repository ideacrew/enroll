FactoryGirl.define do
  factory(:application, :class => FinancialAssistance::Application) do
    family
    assistance_year 2017
    submitted_at {2.months.ago}
    aasm_state "approved"
  end
end