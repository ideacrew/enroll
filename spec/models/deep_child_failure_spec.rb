require "rails_helper"

class ParentDoc
  include Mongoid::Document

  embeds_many :child_docs
end

class ChildDoc
  include Mongoid::Document

  embedded_in :parent_doc
  embeds_many :grand_child_docs
end  

class GrandChildDoc
  include Mongoid::Document

  embedded_in :child_doc
  field :name_column, type: String
  field :date_column, type: Date
end  

describe "Mongoid without bugs on deeply nested documents" do
  let(:parent_doc) { ParentDoc.new({
    :child_docs => [
      ChildDoc.new({
        :grand_child_docs => [
               GrandChildDoc.new(:date_column => original_date_value),
               GrandChildDoc.new(:date_column => original_date_value)
        ]
      })
    ]
  })}

  let(:original_date_value) {
    Date.new(2007, 7, 15)
  }

  let(:date_val) { Date.new(2010, 3, 24) }

  before :each do
    p_doc_id = parent_doc.id
    parent_doc.save!
    p_doc = ParentDoc.find(p_doc_id)
    gc_docs = p_doc.child_docs.first.grand_child_docs
    last_gc = gc_docs.last
    @last_gc_id = last_gc.id
    last_gc.update_attributes!(:date_column => date_val)
    reloaded_p_doc = ParentDoc.find(p_doc_id)
    @gc_reloaded_docs = reloaded_p_doc.child_docs.first.grand_child_docs
  end

  it "should properly update the second grand child document." do
    reloaded_gc = @gc_reloaded_docs.detect { |doc| doc.id.to_s == @last_gc_id.to_s }
    expect(reloaded_gc.date_column).to eq date_val
  end

  it "should not update the first great child document." do
    reloaded_gc = @gc_reloaded_docs.detect { |doc| doc.id.to_s != @last_gc_id.to_s }
    expect(reloaded_gc.date_column).to eq original_date_value
  end
end
