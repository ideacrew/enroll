require 'curl'

module Notifier
  class NoticeKind
    include Mongoid::Document
    include Mongoid::Timestamps

    RECEIPIENTS = {
      "Employer" => "Notifier::MergeDataModels::EmployerProfile",
      "Employee" => "Notifier::MergeDataModels::EmployeeProfile",
      "Broker" => "Notifier::MergeDataModels::BrokerProfile"
    }

    field :title, type: String
    field :description, type: String
    field :identifier, type: String
    field :notice_number, type: String
    field :receipient, type: String, default: "Notifier::MergeDataModels::EmployerProfile"

    embeds_one :cover_page
    embeds_one :template, class_name: "Notifier::Template"
    embeds_one :merge_data_model

    def receipient_class_name
      # receipient.constantize.class_name.underscore
      receipient.to_s.split('::').last.underscore.to_sym
    end

    def to_html(options = {})
      params = { receipient_class_name.to_sym => receipient.constantize.stubbed_object }

      if receipient_class_name.to_sym != :employer_profile
        params.merge!({employer_profile: receipient.constantize.stubbed_object})
      end

      Notifier::NoticeKindsController.new.render_to_string({
        :template => 'notifier/notice_kinds/template.html.erb', 
        :layout => false,
        :locals => { receipient: receipient.constantize.stubbed_object, notice_number: self.notice_number}
      }) + Notifier::NoticeKindsController.new.render_to_string({ 
        :inline => template.raw_body.gsub('${', '<%=').gsub('#{', '<%=').gsub('}','%>').gsub('[[', '<%').gsub(']]', '%>'),
        :layout => 'notifier/pdf_layout',
        :locals => params
      })
    end

    def save_html
      File.open(Rails.root.join("tmp", "notice.html"), 'wb') do |file|
        file << self.to_html({kind: 'pdf'})
      end
    end 
  
    def to_pdf
      WickedPdf.new.pdf_from_string(self.to_html({kind: 'pdf'}), pdf_options)
    end

    def generate_pdf_notice
      File.open(notice_path, 'wb') do |file|
        file << self.to_pdf
      end
      # clear_tmp
    end

    def pdf_options
      {
        margin:  {
          top: 15,
          bottom: 28,
          left: 22,
          right: 22 
        },
        disable_smart_shrinking: true,
        dpi: 96,
        page_size: 'Letter',
        formats: :html,
        encoding: 'utf8',
        header: {
          content: ApplicationController.new.render_to_string({
            template: "notifier/notice_kinds/header_with_page_numbers.html.erb",
            layout: false,
            locals: {notice: self}
            }),
          }
      }
    end

    def notice_path
      Rails.root.join("public", "NoticeTemplate.pdf")
    end

    # def self.markdown
    #   Redcarpet::Markdown.new(ReplaceTokenRenderer,
    #       no_links: true,
    #       hard_wrap: true,
    #       disable_indented_code_blocks: true,
    #       fenced_code_blocks: false,        
    #     )
    # end

    # # Markdown API: http://www.rubydoc.info/gems/redcarpet/3.3.4
    # def to_html
    #   self.markdown.render(template.body)
    # end

    def self.to_csv
      CSV.generate(headers: true) do |csv|
        csv << ['Notice Number', 'Title', 'Description', 'Receipient', 'Notice Template']

        all.each do |notice|
          csv << [notice.notice_number, notice.title, notice.description, notice.receipient, notice.template.try(:raw_body)]
        end
      end
    end
  end
end
