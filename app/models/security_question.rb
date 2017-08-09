class SecurityQuestion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :visible, type: Boolean, default: true

  validates_presence_of :title
  scope :visible, -> { where(visible: true) }
  def status
    visible? ? 'Visible' : 'Invisible'
  end

end
