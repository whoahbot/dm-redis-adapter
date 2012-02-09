require 'spec_helper'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
    @redis = Redis.new(:db => 15)
  end

  describe "finding records tests" do
    before(:all) do
      @redis.flushdb
      class Page
        include DataMapper::Resource

        property :id,   Serial

        has n, :children, 'Page', :child_key => :parent_id
        belongs_to :parent, 'Page', :required => false
      end
      DataMapper.finalize

      @a = Page.create
      @b = Page.create :parent => @a
      @c = Page.create :parent => @a
      @d = Page.create :parent => @c
    end

    it 'should find Page.all :parent_id => @a.id' do
      found = Page.all :parent_id => @a.id
      found.should == [@b,@c]
    end

    it 'should find Page.all :id.not => @a.id' do
      found = Page.all :id.not => @a.id
      found.should == [@b,@c,@d]
    end

    it 'should find Page.all :parent_id.not => @a.id' do
      found = Page.all :parent_id.not => @a.id
      found.should == [@a,@d]
    end

    it 'should find Page.all :parent => @a' do
      found = Page.all :parent => @a
      found.should == [@b,@c]
    end

    it 'should find Page.all :id => [@a.id]' do
      found = Page.all :id => [@a.id]
      found.should == [@a]
    end

    it 'should find Page.all :id => [@a.id, @c.id]' do
      found = Page.all :id => [@a.id, @c.id]
      found.should == [@a,@c]
    end

    it 'should find Page.all :parent_id => [@a.id, @c.id]' do
      found = Page.all :parent_id => [@a.id, @c.id]
      found.should == [@b,@c,@d]
    end

    it 'should find Page.all :parent => [@a,@c]' do
      found = Page.all :parent => [@a,@c]
      found.should == [@b,@c,@d]
    end

    # it fails
    #it 'should be able to map Page.all.map{ |@a| @a.parent }' do
    #  mapped = Page.all.map{ |a| a.parent }
    #  mapped.should == [nil, @a, @a, @c]
    #end

  end

end
