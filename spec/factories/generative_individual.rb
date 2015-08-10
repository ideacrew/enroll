FactoryGirl.define do
  factory(:generative_individual, {class: Person}) do
    first_name { Forgery(:name).first_name }
    last_name { Forgery(:name).first_name }
    gender { Forgery(:personal).gender }
    dob { Date.today }
    addresses { 
      address_count = Random.rand(4)
      if address_count == 0
        []
      else
        (1..address_count).to_a.map do |idx|
          FactoryGirl.build_stubbed :generative_address
        end
      end
    }
    phones { 
      address_count = Random.rand(4)
      if address_count == 0
        []
      else
        (1..address_count).to_a.map do |idx|
          FactoryGirl.build_stubbed :generative_phone
        end
      end
    }
    emails { 
      address_count = Random.rand(4)
      if address_count == 0
        []
      else
        (1..address_count).to_a.map do |idx|
          FactoryGirl.build_stubbed :generative_email
        end
      end
    }
  end

  factory(:generative_person_broker_role, {class: BrokerRole}) do
    person { FactoryGirl.build_stubbed :generative_person}
  end
end
