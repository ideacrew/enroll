module BenefitMarkets
  module Services
    class BenefitMarketService
      def initialize(params = {})
        @factory_class = BenefitMarkets::BenefitMarketFactory
        @params = params
      end

      def build(attrs={})
        @factory_class.build
      end

      def store!(form)
        BenefitMarkets::BenefitMarketFactory.call(form_attributes_to_params(form))
      end

      def form_params_to_attributes(form, benefit_market)
        model_attributes = {
          benefit_market_key: form.benefit_market_key,
          byline: form.byline,
          long_name: form.long_name,
          short_name: form.short_name,
          domain_name: form.domain_name,
          owner_organization: {
            legal_name: form.owner_organization.legal_name,
            profiles: [{
              office_locations: form.owner_organization.profile.office_locations.map do |location|
                {
                  is_primary: location.is_primary,
                  phone: location.phone.attributes.slice(:kind, :area_code, :number, :extension),
                  address: location.address.attributes.slice(:kind, :address_1, :address_2, :city, :state, :zip),
                }
              end
            }]
          }
        }
        benefit_market.assign_attributes(model_attributes)
      end

      def attributes_to_form_params(benefit_market, shop_configuration, individual_configuration, form)
        puts shop_configuration.attributes.inspect
        form.attributes = benefit_market.attributes.merge({
          aca_individual_configuration: individual_configuration.attributes.merge({
            initial_application_configuration: individual_configuration.initial_application_configuration.attributes
          }),
          aca_shop_configuration: shop_configuration.attributes.merge({
            initial_application_configuration: shop_configuration.initial_application_configuration.attributes,
            renewal_application_configuration: shop_configuration.renewal_application_configuration.attributes
          })
        })
        form
      end

      # Load the peristance entities and use them to populate the form
      # attributes.
      #
      # Normally this method would contain only a persistence lookup and
      # attribute mappings.
      # In my case I have to figure out which form subclass I should be using.
      # @param form [Object] The form for which to load the parameters.
      # @return [Object] A form object containing the loaded parameters.
      def load_form_params_from_resource(form)
        benefit_market = find_model_by_id(form.id)
        attributes_to_form_params(benefit_market, form)
      end

      def find_model_by_id(id)
        BenefitMarkets::BenefitMarket.find(id)
      end

      def update(form)
        benefit_market = find_model_by_id(form.id)
        form_params_to_attributes(form, benefit_market)
        store(form, benefit_market)
      end

      def save(form)
        office_locations = form.owner_organization.profile.office_locations.map do |office_location|
          BenefitMarkets::Locations::Factories::OfficeLocation.call is_primary: office_location.is_primary,
            phone_attributes: office_location.phone.attributes,
            address_attributes: office_location.address.attributes
        end
        profile = BenefitMarkets::Organizations::Factories::HbxProfile.call(office_locations)
        owner_organization = BenefitMarkets::Organizations::Factories::OwnerOrganization.call(legal_name: form.owner_organization.legal_name, profile: profile)
        profile.organization = owner_organization
        benefit_market = BenefitMarkets::BenefitMarketFactory.call benefit_market_key: form.benefit_market_key,
          long_name: form.long_name,
          short_name: form.short_name,
          domain_name: form.domain_name,
          owner_organization: owner_organization

        owner_organization.benefit_market = benefit_market

        valid_according_to_factory = BenefitMarkets::BenefitMarketFactory.validate(benefit_market)
        unless valid_according_to_factory
          map_errors_for(benefit_market, onto: form)
          return [false, nil]
        end
        save_successful = benefit_market.save
        unless save_successful
          map_errors_for(benefit_market, onto: form)
          return [false, nil]
        end
        [true, benefit_market]
      end

      def store(form, benefit_market)
        if benefit_market.save
          true
        else
          map_errors_for(benefit_market, onto: form)
          false
        end
      end

      def map_errors_for(benefit_market, onto:)
        benefit_market.owner_organization.errors.each do |att, err|
          onto.owner_organization.errors.add(att, err)
        end

        benefit_market.owner_organization.profiles.first.errors.each do |att, err|
          onto.owner_organization.profile.errors.add(att, err)
        end

        benefit_market.owner_organization.profiles.first.office_locations.each_with_index do |location, index|
          form_location = onto.owner_organization.profile.office_locations[index]

          location.errors.each do |att, err|
            form_location.errors.add(att, err)
          end

          location.phone.errors.each do |att, err|
            form_location.phone.errors.add(att, err)
          end

          location.address.errors.each do |att, err|
            form_location.address.errors.add(att, err)
          end
        end

        benefit_market.errors.each do |att, err|
          onto.errors.add(att, err)
        end
      end
    end
  end
end
