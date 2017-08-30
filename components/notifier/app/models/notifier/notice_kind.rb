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
    field :receipient, type: String, default: "Notifier::MergeDataModels::EmployerProfile"

    embeds_one :cover_page
    embeds_one :template, class_name: "Notifier::Template"
    embeds_one :merge_data_model

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

    def view_template
      'notifier/notice_kinds/template.html.erb'
    end

    def notice_filename
      "#{title.titleize.gsub(/\s*/, '')}"
    end

    def to_html(options = {})
      Notifier::NoticeKindsController.new.render_to_string({ 
        :inline => template.raw_body.gsub('#{', '<%=').gsub('}','%>').gsub('[[', '<%').gsub(']]', '%>'),
        #:template => 'notifier/notice_kinds/template.html.erb',
        :layout => 'notifier/pdf_layout',
        :locals => { employer: Notifier::MergeDataModels::EmployerProfile.stubbed_object, notice_kind: self }
        })
    end
  
    def notice_path
      Rails.root.join("public", "Sample.pdf")
    end

    def to_pdf
      WickedPdf.new.pdf_from_string(self.to_html({kind: 'pdf'}), pdf_options)
    end

    # def to_pdf
    #   WickedPdf.new.pdf_from_string(to_html, pdf_options)
    # end

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
  end
end
