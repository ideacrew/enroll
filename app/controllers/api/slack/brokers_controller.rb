class ApiSlackBrokersController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :require_login
  skip_before_action :authenticate_user_from_token!
  skip_before_action :authenticate_me!

  ## test in slack with:
  ## /all-broker-xmls
  ##
  ## copied from this jenkins job:
  ## https://jenkins.priv.dchbx.org/job/data-all-brokers/configure

  def all_broker_xmls
    token = params[:token]
    user_name = params[:user_name]
    allowed_users = ENV['ALL_BROKER_DATA_USERS'].split(',')

    ## validate the token AND make sure the user requesting it has privligdges
    if token == ENV['SLACK_API_TOKEN'] && allowed_users.include?(user_name)

      # https://arjunphp.com/delete-file-ruby/
      @file = 'broker_xmls.zip'
      @dir = 'broker_xmls'
      File.delete(@file) if File.exist?(@file)
      # https://stackoverflow.com/questions/6015692/how-to-delete-a-non-empty-directory-using-the-dir-class
      FileUtils.rm_r(@dir) if File.directory?(@dir)
      Dir.mkdir(@dir)

      ## copied from scripts/write_broker_files.rb
      controller = Events::BrokersController.new
      properties_slug = Struct.new(:reply_to, :headers)
      connection_slug = Struct.new(:broker_npn) do
        def create_channel
          self
        end

        def default_exchange
          self
        end

        def close
        end

        def publish(payload, headers)
          Dir.mkdir(@dir) unless File.exists?(@dir)
          File.open(File.join(@dir, "#{broker_npn}.xml"), 'w') do |f|
            f.puts payload
          end
        end
      end
      npn_list = Person.where("broker_role.aasm_state" => "active").map do |pers|
        pers.broker_role.npn
      end
      npn_list.each do |npn|
        ps = properties_slug.new("", {:broker_id => npn})
        controller.resource(connection_slug.new(npn), "", ps, "")
      end

      ## generate zip file of broker xmls
      # https://www.botreetechnologies.com/blog/password-protected-zip-using-ruby-on-rails/
      broker_xml_files = Dir.entries(@dir)
      zip_password = ENV['ALL_BROKER_DATA_ZIP_PASSWORD']
      buffer = Zip::OutputStream.write_buffer(::StringIO.new(''), Zip::TraditionalEncrypter.new(zip_password)) do |zos|
        files.each do |bxf|
          zos.put_next_entry bxf
          zos.write File.open("#{@dir}/#{bxf}").read
        end
      end
      File.open(@file, 'wb') {|f| f.write(buffer.string) }
      buffer.rewind

      s3 = Aws::S3::Resource.new(region: 'us-east-1')
      bucket = ENV['ALL_BROKER_DATA_S3_BUCKET']
      key = ENV['ALL_BROKER_DATA_S3_KEY']
      # acl:'public-read'
      s3.bucket(bucket).object(key).put(body:buffer, storage_class:'INTELLIGENT_TIERING')
      # return S3 public link to csv (zipped + password protected)
      s3_link = "https://#{bucket}.s3.amazonaws.com/#{key}"

      @ouput_lines = [s3_link]

      ## respond on slack
      slack = Slack::Incoming::Webhooks.new params[:response_url]
      slack.post @output_lines.join("\r\n")
    else
      ## error out
      ## respond
      slack = Slack::Incoming::Webhooks.new params[:response_url]
      slack.post "Slack user with username #{user_name} does not have permission to run all-broker-xmls. Please contact #{ENV['SLACK_API_ADMIN']} with this error message to be given permission."
    end
  end
end
