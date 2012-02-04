require 'spec_helper'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
  end

  after(:all) do
    Redis.new(:db => 15).flushdb
  end

  describe "referential assosciations" do
    it "should allow the assosciation to go both ways" do
      class User
        class Link
          include DataMapper::Resource

          # the person who is doing the following
          belongs_to :follower, 'User', :key => true

          # the person who is being followed
          belongs_to :followed, 'User', :key => true
        end

        include DataMapper::Resource

        property :id,                   Serial
        property :full_name,            String,   :length => 255, :required => true
        property :email,                String,   :length => 320, :required => true

        has n, :links_to_followed_users, 'User::Link', :child_key => [:follower_id]
        has n, :links_to_followers, 'User::Link', :child_key => [:followed_id]
        has n, :followed_users, User, :through => :links_to_followed_users, :via => :followed
        has n, :followers, User, :through => :links_to_followers, :via => :follower
      end

      DataMapper.finalize

      user1 = User.create(:email => "joe@example.com", :full_name => "joe")
      user2 = User.create(:email => "bob@example.com", :full_name => "bob")

      user1.followed_users << user2
      user1.save
      #user2.links_to_followers.count.should == 1
    end
  end
end
