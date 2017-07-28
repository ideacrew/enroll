module Notifier
  class Notice

    def initialize(notice_id, attribute_hash, options={})
    end

    def output_notice
      output_cover_page
      output_head
      output_body_start
      output_body
      output_body_end
      output_end
    end

    def output_cover_page
    end

    def output_head
    end

    def output_body_start
    end

    def output_body
    end

    def output_body_end
    end

    def output_end
    end

  end
end
