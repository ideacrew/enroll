# Embedded model that stores a location address
class Blacklist
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable
end
