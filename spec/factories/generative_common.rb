FactoryBot.define do
  factory(:generative_email, {class: Email}) do
    kind { 
      Email::KINDS[Random.rand(2)]
    }
    address { Forgery('email').address }
  end

  factory(:generative_phone, {class: Phone}) do
    kind { 
      Phone::KINDS[Random.rand(5)]
    }
    full_phone_number { Forgery('address').phone }
  end

  factory(:generative_address, {class: Address}) do
    kind { 
      Address::KINDS[Random.rand(3)]
    }
    address_1 Forgery('address').street_address
    address_2 { 
      if Forgery('basic').boolean
        Forgery('address').street_address
      else
        nil
      end
    }
    state Forgery('address').state_abbrev
    zip Forgery('address').zip
    city Forgery('address').city
  end
end
