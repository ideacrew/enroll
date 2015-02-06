FactoryGirl.define do
  factory :employer do
    name "acme widgets"
    dba "widgetworks"
    fein '111111111'
    entity_kind :c_corporation
  end
end
