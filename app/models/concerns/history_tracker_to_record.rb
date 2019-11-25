module HistoryTrackerToRecord
  extend ActiveSupport::Concern

  def history_tracker_to_record(ht_date)
    # Example: If is a HistoryTracker in person model
    # history_track.trackable will return consumer_role
    # if the consumer_role was modified. trackable_root
    # will return person for both
    self.reload
    all_tracks = self.history_tracks.unscoped.to_a.sort_by(&:created_at)
    tracks_to_reverse = all_tracks.reject do |ht|
      (ht.created_at <= ht_date) || ((ht.created_at.to_f - self.created_at.to_f).abs < 1.1)
    end.reverse

    tracks_to_reverse.each do |rt|
      begin
      if rt.association_chain.length < 2
        self.attributes = rt.undo_attr(nil)
      else
        case rt.action
        when "create"
          association_chain_without_last = rt.association_chain[1..-2]
          last_in_chain = rt.association_chain.last
          chain_target = association_chain_without_last.inject(self) do |acc, chain_location|
            if acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).detect do |ao|
                ao.id.to_s == chain_location["id"].to_s
              end
            else # embeds_one
              acc.send(chain_location["name"].to_sym)
            end
          end
          if chain_target.send(last_in_chain["name"]).is_a?(Enumerable)
            remaining_items = chain_target.send(last_in_chain["name"].to_sym).reject do |record|
              record.id.to_s == last_in_chain["id"].to_s
            end
            chain_target.send((last_in_chain["name"] + "=").to_sym, remaining_items)
          else
            chain_target.send((last_in_chain["name"] + "=").to_sym, nil)
          end
        when "destroy"
          association_chain_without_last = rt.association_chain[1..-2]
          last_in_chain = rt.association_chain.last
          chain_target = association_chain_without_last.inject(self) do |acc, chain_location|
            if acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).detect do |ao|
                ao.id.to_s == chain_location["id"].to_s
              end
            else # embeds_one
              acc.send(chain_location["name"].to_sym)
            end
          end
          if chain_target.send(last_in_chain["name"]).is_a?(Enumerable)
            chain_target.send(last_in_chain["name"].to_sym).build(rt.original)
          else
            chain_target.send(("build_" + last_in_chain["name"]).to_sym, rt.original)
          end
        else
          association_chain_without_first = rt.association_chain[1..-1]
          chain_target = association_chain_without_first.inject(self) do |acc, chain_location|
            if acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).detect do |ao|
                ao.id.to_s == chain_location["id"].to_s
              end
            else # embeds_one
              acc.send(chain_location["name"].to_sym)
            end
          end
          chain_target.attributes = rt.undo_attr(nil)
        end
      end
      rescue Exception => e
        log_string = e.inspect + " - ASSOCIATION CHAIN:" + rt.association_chain.inspect + " - HISTORY TRACK: " + rt.inspect + " - PERSON: " + self.inspect
        Rails.logger.error("[IVL ELIG AUDIT]") { log_string }
        STDERR.puts log_string
        raise e
      end
    end

    self
  end
end