module Notifier
  class Notice

    def initialize(template_id, attribute_hash, options={})
    end

    def compose_notice
      compose_cover_page
      compose_head
      compose_body_start
      compose_body
      compose_body_end
      compose_end
    end

    def compose_cover_page
    end

    def compose_head
    end

    def compose_body_start
    end

    def compose_body
      raise "Called abstract method: compose_body"
    end

    def compose_body_end
    end

    def compose_end
    end

  end
end
