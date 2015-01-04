class Broker
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  KINDS = ["broker", "tpa"]

  # include MergingModel
  # extend Mongorder

  # attr_accessible :email, :password, :password_confirmation, :remember_me #, :username

  field :kind, type: String

  # Broker National Producer Number (unique identifier)
  field :npn, type: String
  field :is_active, type: Boolean, default: true

  embeds_one :mailing_address, class_name: "Address", inverse_of: :broker_mailing_address

  delegate :first_name, :first_name=, to: :person, prefix: true, allow_nil: true

  # has_many :consumers
  # has_many :employers

  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid broker type"
  validates_presence_of :npn

  def parent
    raise "undefined parent: Person" unless person? 
    self.person
  end

  # has_many association
  def consumers
    parent.consumers.where(:broker_id => self._id)
  end

  def employers
    Employer.find_by_broker_id(self._id)
  end

  def self.default_search_order
    [
      ["name_last", 1],
      ["name_first", 1]
    ]
  end

  def self.search_hash(s_str)
    clean_str = s_str.strip
    s_rex = Regexp.new(Regexp.escape(clean_str), true)
    additional_exprs = []
    if clean_str.include?(" ")
      parts = clean_str.split(" ").compact
      first_re = Regexp.new(Regexp.escape(parts.first), true)
      last_re = Regexp.new(Regexp.escape(parts.last), true)
      additional_exprs << {:name_first => first_re, :name_last => last_re}
    end
    {
      "$or" => ([
        {"name_first" => s_rex},
        {"name_middle" => s_rex},
        {"name_last" => s_rex},
        {"npn" => s_rex}
      ] + additional_exprs)
    }
  end

  def self.find_or_create(m_broker)
    found_broker = Broker.find_by_npn(m_broker.npn)
    if found_broker.nil?
      m_broker.save!
      return m_broker
    else
      found_broker.merge_without_blanking(m_broker,
        :b_type,
        :name_pfx,
        :name_first,
        :name_middle,
        :name_last,
        :name_sfx,
        :name_full,
        :npn
        )

      m_broker.addresses.each { |a| found_broker.merge_address(a) }
      m_broker.emails.each { |e| found_broker.merge_email(e) }
      m_broker.phones.each { |p| found_broker.merge_phone(p) }

      found_broker.save!

      return found_broker
    end
  end

  def self.find_or_create_without_merge(m_broker)
    found_broker = Broker.find_by_npn(m_broker.npn)
    if found_broker.nil?
      m_broker.save!
      return m_broker
    end
    found_broker
  end

  def self.find_by_npn(value)
    Broker.where({npn: value}).first unless value.blank?
  end

  def merge_address(m_address)
    unless (self.addresses.any? { |a| a.match(m_address) })
      self.addresses << m_address
    end
  end

  def merge_email(m_email)
    unless (self.emails.any? { |e| e.match(m_email) })
      self.emails << m_email
    end
  end

  def merge_phone(m_phone)
    unless (self.phones.any? { |p| p.match(m_phone) })
      self.phones << m_phone
    end
  end

  def is_active?
    self.is_active
  end

private

  def initialize_name_full
    self.name_full = full_name
  end

end
