require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','service_visits_parser')

module Parser
  class ServiceVisitsListParser
    include HappyMapper

    tag 'serviceVisitList'

    has_many :service_visits, Parser::ServiceVisitsParser, tag: "serviceVisit"

    def to_hash
      {
          service_visits: service_visits.map(&:to_hash)
      }
    end
  end
end
