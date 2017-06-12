module TransportCredentials
  class SftpTransportCredential < TransportCredential
    field :user, type: String
    field :password, type: String
    field :host, type: String
    field :key_pem, type: String

    validates_presence_of :user, :allow_blank => false
    validates_presence_of :host, :allow_blank => false
    validates_presence_of :password, :allow_blank => false, :if => ->(record) { record.key_pem.blank? }
    validates_presence_of :key_pem, :allow_blank => false, :if => ->(record) { record.password.blank? }

    def self.credentials_for_sftp(uri)
      return nil if uri.userinfo.blank?
      return nil if uri.user.blank?
      lookup_username = URI.decode(uri.user)
      self.where({user: lookup_username, host: uri.host}).first
    end

    def sftp_options
      if key_pem.blank?
        { :password => password }
      else
        { :key_data => [key_pem] }
      end
    end
  end
end
