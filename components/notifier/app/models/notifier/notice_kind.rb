module Notifier
  class Notice
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String
    field :description, type: String

    embeds_one :cover_page
    embeds_one :template
    embeds_one :merge_data_model

    def self.markdown
      Redcarpet::Markdown.new(ReplaceTokenRenderer,
          no_links: true,
          hard_wrap: true,
          disable_indented_code_blocks: true,
          fenced_code_blocks: false,        
        )
    end


    # Markdown API: http://www.rubydoc.info/gems/redcarpet/3.3.4
    def to_html
      self.markdown.render(template.body)
    end

    def to_pdf
      WickedPdf.new.pdf_from_string(to_html, pdf_options)
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
            template: header,
            layout: false,
            locals: {notice: notice}
            }),
          }
      }
    end



  end
end
