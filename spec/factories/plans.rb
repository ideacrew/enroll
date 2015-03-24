FactoryGirl.define do
  factory :plan, :class => Directory::Plan do
    sequence(:hbx_id)    { |n| n + 12345 }
    sequence(:name)      { |n| "BlueChoice Silver#{n} $2,000" }
    abbrev              "BC Silver $2k"
    sequence(:hios_id, (10..99).cycle)  { |n| "86052DC04000#{n}-01" } 
    active_period        2014..2015
    metal_level         "silver"
  end
end
