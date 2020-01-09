module Versioning
  class VersionCollection
    include Enumerable

    attr_reader :versions

    def initialize(model_record)
      @record = model_record
      @versions = build_version_list
      @min_ts = @version_list.min_by(&:timestamp).timestamp
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

    private

    def build_version_list
      @record.reload
      version_list = [RecordVersion.new(@record, :record, @record.updated_at)]
      if @record.versions.any?
        legacy_versions = @record.versions.map do |rv|
          RecordVersion.new(@record, :version, rv.updated_at)
        end

        version_list = version_list + legacy_versions
      end
      if @record.history_tracks.any?
        history_track_dates = @record.filtered_history_tracks.map do |ht|
          ht.created_at
        end
        history_track_stamps = [history_track_dates + record.created_at].compact.uniq
        ht_versions = history_track_stamps.map do |hts|
          RecordVersion.new(@record, :history_track, hts)
        end
        version_list = version_list + ht_versions
      end
      version_list.sort_by(&:timestamp)
    end
  end
end