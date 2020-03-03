module Queries
  class AgenciesQuery
    include Enumerable

    def each
      agency_aggregate.each do |rec|
        model  = ::Mongoid::Factory.from_db(
          BenefitSponsors::Organizations::Organization,
          rec
        )
        yield model
      end
    end

    def each_with_index
      i = 0
      agency_aggregate.each do |rec|
        model = ::Mongoid::Factory.from_db(
          BenefitSponsors::Organizations::Organization,
          rec
        )
        yield model, i
        i = i + 1
      end
    end

    def agency_aggregate
      BenefitSponsors::Organizations::Organization.collection.aggregate([
        {"$match" => {
          "profiles._type" => /.*AgencyProfile$/
        }},
        {
          "$project" => {
            "dba" => 1,
            "legal_name" => 1,
            "profiles" => 1
          }
        },
        {
          "$unwind" => "$profiles"
        },
        {
          "$match" => {
            "$or" => [
              {
                "profiles._type" => /.*BrokerAgencyProfile$/
              },
              {
                "profiles._type" => /.*GeneralAgencyProfile$/
              }
            ]
          }
        },
        {
          "$group" => {
            "_id" => "$_id",
            "dba" => {"$last" => "$dba"},
            "legal_name" => {"$last" => "$legal_name"},
            "profiles" => {
              "$push" => "$profiles"
            }
          }
        }
      ])
    end
  end
end