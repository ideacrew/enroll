module Notifier
  class NoticeKindsController < ApplicationController

    def new
      @notice_kind = Notifier::NoticeEvent.new
    end
  end
end
