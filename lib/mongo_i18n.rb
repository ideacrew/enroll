# encoding: UTF-8
module MongoI18n
  class Store
    attr_reader :collection

    def initialize(collection, options={})
      @collection, @options = collection, options
    end

    def []=(key, value, options = {})
      key = key.to_s
      doc = {:key => key, :value => value}
      collection.find_or_create_by(doc)
    end

    def [](key, options=nil)
      if doc = collection.where(:key=> key.to_s) and doc.any?
        doc.first.value.try(:to_s)
      end
    end

    def keys
      collection.all.pluck(:key).compact || []
    end
  end

  def self.store
    MongoI18n::Store.new(Translation)
  end
end
