FactoryGirl.define do
  factory :employer do
    legal_name "acme widgets"
    dba "widgetworks"
    sequence(:fein, 111111111)
    entity_kind :c_corporation
  end
end
