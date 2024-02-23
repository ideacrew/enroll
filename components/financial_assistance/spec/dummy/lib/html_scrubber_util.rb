# frozen_string_literal: true

# Utility module to perform scrubbing and prevent XSS attacks.
module HtmlScrubberUtil
  def sanitize_html(value)
    scrubber = Rails::Html::TargetScrubber.new
    frag = Loofah.fragment(value)
    frag.scrub!(scrubber)
    frag.to_s.html_safe
  end
end