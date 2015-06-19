class HbxPortal
  include Mongoid::Document
  include Mongoid::Timestamps
  embeds_one :inbox, as: :recipient
  after_create :create_inbox

  def create_inbox
  	self.inbox = Inbox.new
  end  

end

