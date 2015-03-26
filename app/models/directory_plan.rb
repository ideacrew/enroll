FactoryGirl.define do
  factory :directory_plan, :class => Directory::Plan do
    sequence(:hbx_id)    { |n| n + 12345 }
    hbx_plan_id '1234'
    hbx_carrier_id '1234'
    hios_id '1234'
    active_period 2014..2015
    name 'nice plan'
    abbrev 'np'
    type 'Dental'
    metal_level 'gold'
    doc_url 'http://niceplan.com/nice-doc'
  end
end