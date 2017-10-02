namespace :carrier_contacts do
  desc "populates carrier contacts"
  # rake carrier_contacts:populate
  task :populate => [:environment] do
    carriers = Organization.where("carrier_profile" => {"$exists"=> true})

    carriers.each do |carrier|
      carrier = carrier.carrier_profile
      if carrier.legal_name == "Aetna"
        carrier.carrier_contacts.create(kind:'individual',country_code:'1',area_code:'855',number:'5866959')
        carrier.carrier_contacts.create(kind:'brokers',country_code:'1',area_code:'888',number:'4222128')
        carrier.carrier_contacts.create(kind:'employers',country_code:'1',area_code:'855',number:'8853289')
      elsif carrier.legal_name == "BestLife"
        carrier.carrier_contacts.create(kind:'main',country_code:'1',area_code:'800',number:'4330088')
      elsif carrier.legal_name == "CareFirst"
        carrier.carrier_contacts.create(kind:'main',country_code:'1',area_code:'855',number:'4443119')
      elsif carrier.legal_name == "Delta Dental"
        carrier.carrier_contacts.create(kind:'main',country_code:'1',area_code:'800',number:'4710236')
        carrier.carrier_contacts.create(kind:'main2',country_code:'1',area_code:'800',number:'4710275')
      elsif carrier.legal_name == "Dentegra"
        carrier.carrier_contacts.create(kind:'main',country_code:'1',area_code:'800',number:'4710284')
      elsif carrier.legal_name == "Dominion"
        carrier.carrier_contacts.create(kind:'main',country_code:'1',area_code:'855',number:'2243016')
      elsif carrier.legal_name == "Kaiser"
        carrier.carrier_contacts.create(kind:'main',country_code:'1',area_code:'800',number:'7777902')
      elsif carrier.legal_name == "MetLife"
        carrier.carrier_contacts.create(kind:'main',country_code:'1',area_code:'855',number:'6382221')
      elsif carrier.legal_name == "UnitedHealthcare"
        carrier.carrier_contacts.create(kind:'main',country_code:'1',area_code:'877',number:'8562430')
      end
    end
  end
end
