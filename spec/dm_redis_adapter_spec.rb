require File.dirname(__FILE__) + '/spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/redis_adapter.rb'))

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    DataMapper::Adapters::RedisAdapter.redis.select_db(15)
    
    class Post
      include DataMapper::Resource
      
      property :id,   Serial
      property :text, Text
    end
    
    @post   = Post.create(:text => "I'm a stupid blog!")
    @post2  = Post.create(:text => "I'm another stupid blog!")
  end
  
  describe "create" do
    it "should create an instance of the specified class" do
      @post.should be_an_instance_of(Post)
    end
    
    it "should set an id for it's serial field when saved" do
      @post.id.should_not be_nil
    end
    
    it "should increment the serial field on each create" do
      new_post_id = Post.create(:text => "Hey, I'm a cretin!").id
      new_post_id.should == @post2.id + 1
    end
  end
  
  describe "get" do
    it "should return all records" do
      Post.all.should include(@post, @post2)
    end
  end
end