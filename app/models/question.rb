class Question
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :visible, type: Boolean, default: true

  validates_presence_of :title

  def status
    visible?? 'Visible' : 'Invisible'
  end

end
