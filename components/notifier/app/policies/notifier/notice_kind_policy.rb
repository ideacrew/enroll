# frozen_string_literal: true

module Notifier
  # This is pundit policy for notice kind
  class NoticeKindPolicy < ApplicationPolicy

    def index?
      can_view_notices?
    end

    def show?
      can_view_notices?
    end

    def new?
      can_edit_notices?
    end

    def edit?
      can_edit_notices?
    end

    def create?
      can_edit_notices?
    end

    def update?
      can_edit_notices?
    end

    def preview?
      can_view_notices?
    end

    def delete_notices?
      can_edit_notices?
    end

    def download_notices?
      can_view_notices?
    end

    def upload_notices?
      can_edit_notices?
    end

    def tokens?
      can_view_notices?
    end

    def placeholders?
      can_view_notices?
    end

    def recipients?
      can_view_notices?
    end

    def can_view_notices?
      return false if user.blank?

      staff_role = user.person.hbx_staff_role
      staff_role&.permission&.can_view_notice_templates
    end

    def can_edit_notices?
      return false if user.blank?

      staff_role = user.person.hbx_staff_role
      staff_role&.permission&.can_edit_notice_templates
    end
  end
end
