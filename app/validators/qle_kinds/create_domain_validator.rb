module QleKinds
  class CreateDomainValidator < BenefitSponsors::BaseDomainValidator
    params do
      required(:user).value(:filled?)
      required(:request).value(:filled?)
      required(:service).value(:filled?)
    end

    rule(:request, :service) do
      unless values[:service].title_is_unique?(values[:request].title)
        key(:duplicate_title).failure(:duplicate_title)
      end
    end
  end
end
