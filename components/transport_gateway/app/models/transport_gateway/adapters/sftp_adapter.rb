require 'net/ssh'
require 'net/sftp'
require 'tempfile'

module TransportGateway
  class Adapters::SftpAdapter
    include ::TransportGateway::Adapters::Base

    attr_accessor :user
    attr_accessor :credential_options

    def receive_message(message)
      raise ArgumentError.new "source file not provided" if message.from.blank?

      target_uri = message.from

      parse_credentials(target_uri)
      check_credential_provider(target_uri)
      if @user.blank? || @credential_options.blank?
        raise ArgumentError.new("source server username:password not provided")
      end
      
      source_stream = Tempfile.new('tgw_sftp_adapter_dl')

      begin
        Net::SFTP.start(target_uri.host, @user, default_options.merge(credential_options)) do |sftp|
          sftp.download!(target_uri.path, source_stream)
        end
        Sources::TempfileSource.new(source_stream)
      rescue
        source_stream.close
        source_stream.unlink
      end
    end

    def send_message(message)
      raise ArgumentError.new "source data not provided" if (message.from.blank? && message.body.blank?)
      raise ArgumentError.new "destination not provided" unless message.to.present?

      target_uri = message.to

      parse_credentials(target_uri)
      check_credential_provider(target_uri)
      if @user.blank? || @credential_options.blank?
        raise ArgumentError.new("target server username:password not provided")
      end

      source = provide_source_for(message)

      begin
        Net::SFTP.start(target_uri.host, @user, default_options.merge(@credential_options)) do |sftp|
          find_or_create_target_folder_for(sftp, target_uri.path)

          sftp.upload!(source.stream, target_uri.path)
        end
      ensure
        source.cleanup
      end
    end

    def provide_source_for(message)
      unless message.body.blank?
        return Sources::StringIOSource.new(message.body)
      end
      gateway.receive_message(message)
    end

    def send_messages(messages)
      handle1 = sftp.open!("/path/to/file1")
      handle2 = sftp.open!("/path/to/file2")

      r1 = sftp.read(handle1, 0, 1024)
      r2 = sftp.read(handle2, 0, 1024)

      sftp.loop { [r1, r2].any? { |r| r.pending? } }

      puts "chunk #1: #{r1.response[:data]}"
      puts "chunk #2: #{r2.response[:data]}"
    end

    private
    def check_credential_provider(target_uri)
      return nil if credential_provider.blank?
      found_credentials = credential_provider.credentials_for(target_uri)
      return nil if found_credentials.blank?
      @user = found_credentials.user
      @credential_options = found_credentials.sftp_options
    end

    def parse_credentials(uri)
      return nil if uri.user.blank? || uri.password.blank?
      @user     ||= URI.decode(uri.user)
      @credential_options ||= {:password => URI.decode(uri.password)}
    end

    def find_or_create_target_folder_for(sftp, path)
      folder = File.dirname(path)
      begin
        sftp.stat!(folder)
      rescue
        sftp.mkdir!(folder)
      end
    end


    # open session and block until connection is initialized
    def open_session(ssh)
      sftp = Net::SFTP::Session.new(ssh)
      sftp.loop { sftp.opening? }
      sftp
    end

    def open(uploader, *args)
      Rails.logger("Starting upload...")
    end

    def close(uploader, *args)
      Rails.logger("Upload complete")
    end

    def finish(uploader, *args)
      Rails.logger("All done")
    end

    def default_options
      { :non_interactive => true }
    end

  end
end
