require File.expand_path("../spec_helper", __FILE__)
require 'dm-core'
require 'dm-redis-adapter/spec/setup'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
  end

  it "should allow has n :through" do
    class Book
      include DataMapper::Resource

      property :id,   Serial
      property :name, String

      has n, :book_tags
      has n, :tags, :through => :book_tags
    end

    class Tag
      include DataMapper::Resource

      property :id,   Serial
      property :name, String

      has n, :book_tags
      has n, :books, :through => :book_tags
    end

    class BookTag
      include DataMapper::Resource

      property :id,   Serial
      # property :book_id, Integer, :index => true
      # property :tag_id,  Integer, :index => true

      belongs_to :book
      belongs_to :tag
    end

    b = Book.create(:name => "Harry Potter")
    t = Tag.create(:name => "fiction")

    b.tags << t
    b.save

    b2 = Book.get(b.id)
    b2.tags.should == [t]
  end
end
