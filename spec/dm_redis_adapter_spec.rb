require File.dirname(__FILE__) + '/spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/redis_adapter.rb'))

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    class Post
      include DataMapper::Resource
      
      property :id,   Serial
      property :text, String
    end
  end
  
  describe "Repository" do
    it "should return the correct adapter name" do
      DataMapper.repository.adapter.uri[:adapter].should == 'redis'
    end
    
    it "should allow the user to configure the port" do
      DataMapper.repository.adapter.uri[:port].should == 6379
    end
  end
  
  describe "creating new records" do
    before(:each) do
      @post = Post.create(:text => "I'm a stupid blog!")
    end
    
    it "should create an instance of the specified class" do
      @post.should be_an_instance_of(Post)
    end
    
    it "should set an id for it's serial field when saved" do
      @post.id.should_not be_nil
    end
    
    it "should increment the serial field on each create" do
      @post.save
      new_post_id = Post.create(:text => "Hey, I'm a cretin!").id
      new_post_id.should == @post.id + 1
    end
    
    it "should save the attributes for the new record" do
      pending
      Post.get(@post.id).text.should == "I'm a stupid blog!"
    end
  end
end