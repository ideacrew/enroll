module Versioning
  class VersionCollection
    include Enumerable

    attr_reader :versions

    def initialize(model_record, additional_version_at = nil)
      @record = model_record
      @versions = build_version_list(additional_version_at)
      @min_ts = @versions.min_by(&:timestamp).timestamp
    end

    def version_at(v_timestamp)
      return nil if v_timestamp < @min_ts
      remaining_versions = @versions.reject do |rv|
        rv.timestamp > v_timestamp
      end
      return nil if remaining_versions.empty?
      remaining_versions.last.resolve_to_model
    end

    def each
      versions.each do |v|
        yield v
      end
    end

    protected

    def optional_version_at(a_time)
      return nil if a_time < @record.created_at
      return RecordVersion.new(@record, :record, @record.updated_at) if @record.updated_at <= a_time
      history_tracks = @record.filtered_history_tracks.to_a
      return nil unless history_tracks.any?
      remaining_hts = history_tracks.reject do |ht|
        ht.created_at > a_time
      end
      last_history_track = remaining_hts.to_a.sort do |a,b|
        @record.sort_history_tracks(a,b)
      end.last
      return nil unless last_history_track
      RecordVersion.new(@record, :history_track, a_time)
    end

    def build_version_list(additional_version_at = nil)
      @record.reload
      version_list = [RecordVersion.new(@record, :record, @record.updated_at)]
      if additional_version_at
        optional_version = optional_version_at(additional_version_at)
        if optional_version
          version_list = version_list + [optional_version]
        end
      end
      if @record.versions.any?
        legacy_versions = @record.versions.to_a.map do |rv|
          RecordVersion.new(@record, :version, rv.updated_at)
        end

        version_list = version_list + legacy_versions
      end
      if @record.history_tracks.to_a.any?
        history_track_dates = @record.filtered_history_tracks.map do |ht|
          ht.created_at
        end
        history_track_stamps = (history_track_dates + [@record.created_at]).compact.uniq
        if @record.versions.any?
          last_recorded_version_ts = @record.versions.to_a.map(&:updated_at).max
          if last_recorded_version_ts
            history_track_stamps = history_track_stamps.reject do |hts|
              hts <= last_recorded_version_ts
            end
          end
        end
        ht_versions = history_track_stamps.map do |hts|
          RecordVersion.new(@record, :history_track, hts)
        end
        version_list = version_list + ht_versions
      end
      version_list.sort_by(&:timestamp)
    end
  end
end