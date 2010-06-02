require File.expand_path("../spec_helper", __FILE__)
require 'redis'
require 'rubygems'
require 'dm-validations'
require 'dm-types'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
  end

  it "should validate unique entries that are indexed" do
    class Crumblecake
      include DataMapper::Resource
      validates_is_unique :flavor

      property :id,      Serial
      property :flavor,  String, :index => true
    end
    
    Crumblecake.create(:flavor => "snozzbler")
    Crumblecake.new(:flavor => "snozzbler").valid?.should be_false
  end

  describe "json support" do
    before(:all) do
      class Host
        include DataMapper::Resource

        property :id,     Serial
        property :name,   String
        property :env,    DataMapper::Property::Json, :default => lambda { {} }
      end
    end

    it "should be able to store json blocks" do
      h = Host.create( :name => "new_vm", :env => {"foo" => "bar"} )

      h.reload
      h.env["foo"].should == "bar"
    end

    it "should be able to update json blocks" do
      h = Host.create( :name => "new_vm" )
      h.env = h.env.merge "baz" => "bof"
      h.save
      h.reload.env["baz"].should == "bof"
    end
  end

  it "should allow me to delete properties" do
    class User
      include DataMapper::Resource

      property :id,   Serial
      property :name, String
    end

    u = User.create :name => "bpo"
    u.reload.name.should == "bpo"
    u.name = nil
    u.save
    u.reload.name.should == nil
  end
  
  it "should store Date fields" do
    class Post
      include DataMapper::Resource
      
      property :id,        Serial
      property :posted_at, Date
    end
    
    p = Post.create :posted_at => Date.today
    
    Post.first.posted_at.should be_a(Date)
  end

  after(:all) do
    redis = Redis.new(:db => 15)
    redis.flushdb
  end
end
