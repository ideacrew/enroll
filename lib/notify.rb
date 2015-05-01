module Notify
  include Acapi::Notifiers

  def notify_change_event(obj, attributes={}, relationshop_attributes={})
    modal_name = obj.class.to_s.downcase
    if obj.new_record?
      notify("acapi.info.events.enrollment.#{modal_name}_created", obj.to_xml)
    else
      payload = payload(obj, attributes: attributes, relationshop_attributes: relationshop_attributes)
      notify("acapi.info.events.enrollment.#{modal_name}_changed", payload.to_xml) if payload.present?
    end
  rescue => e
    Rails.logger(e)
  end

  def payload(obj, attributes:, relationshop_attributes:)
    payload = []
    # for attributes
    attributes.each do |k, v|
      if (ary = v & obj.changed) and ary.present?
        tmp_ary = []
        ary.each do |item|
          tmp_ary.push({item => obj.send("#{item}_change")})
        end
        payload.push({k => tmp_ary})
      end
    end
    # for relationshops
    relationshop_attributes.each do |k, v|
      ary = []
      v.each do |item|
        relation = obj.send(item)
        if relation.present?
          if relation.select(&:new_record?).present?
            ary.push({item => relation.select(&:new_record?)})
          else
            if change_items = relation.select(&:changed?) and change_items.count > 0
              ary.push({item => change_items.map(&:changes)})
            end
          end
        end
      end
      payload.push({k => ary}) if ary.present?
    end
    payload
  end
end
