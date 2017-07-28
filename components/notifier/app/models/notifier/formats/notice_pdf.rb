module Notifier
  class Formats::NoticePdf < Notice


    def compose_notice
      compose_cover_page
      compose_body
    end

    def compose_cover_page
    end

    def compose_body
    end

  end
end
