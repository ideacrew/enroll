module Fdsh
  module Ridp
    class RidpResponseServiceModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :primary_member_hbx_id, type: String
      field :event_kind, type: String
      field :ridp_eligibility, type: Hash

    end
  end
end
