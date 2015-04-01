class Inbox
  include Mongoid::Document

  field :access_key, type: String

  # Enable polymorphic associations
  embedded_in :recipient, polymorphic: true

  embeds_many :messages

  before_create :generate_acccess_key

private
  def generate_acccess_key
    self.access_key = [id.to_s, SecureRandom.hex(10)].join
  end
end
