require File.expand_path("../spec_helper", __FILE__)
require 'dm-validations'
require 'dm-types'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15,
    })
  end

  it "should validate unique entries that are indexed" do
    class Crumblecake
      include DataMapper::Resource
      validates_uniqueness_of :flavor

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
        property :env,    DataMapper::Property::Json, :default => {}
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

    Post.create :posted_at => Date.today
    Post.first.posted_at.should be_a(Date)
  end

  it "should get the first and last model inserted" do
    class GangMember
      include DataMapper::Resource

      property :id,       Serial
      property :nickname, String
    end

    joey = GangMember.create(:nickname => "Joey 'two-times'")
    bobby = GangMember.create(:nickname => "Bobby 'three-fingers'")

    GangMember.first.should == joey
    GangMember.last.should == bobby
  end

  it "should pull up the first pirate that matches the nickname" do
    class Blackguard
      include DataMapper::Resource

      property :id,       Serial
      property :nickname, String, :index => true
    end

    petey = Blackguard.create(:nickname => "Petey 'one-eye' McGraw")
    james = Blackguard.create(:nickname => "James 'cannon-fingers' Doolittle")
    Blackguard.first(:nickname => "James 'cannon-fingers' Doolittle").should == james
  end

  it "should not mark the first pirate as destroyed" do
    class Blackguard
      include DataMapper::Resource

      property :id,       Serial
      property :nickname, String, :index => true
    end

    petey = Blackguard.create(:nickname => "Petey 'one-eye' McGraw")
    james = Blackguard.create(:nickname => "James 'cannon-fingers' Doolittle")
    Blackguard.get(petey.id).should_not be_destroyed
    Blackguard.first(:nickname => "James 'cannon-fingers' Doolittle").should_not be_destroyed
  end

  after(:each) do
    redis = Redis.new(:db => 15)
    redis.flushdb
  end
end
