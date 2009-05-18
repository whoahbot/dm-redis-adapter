require 'rubygems'
require 'dm-core'
require 'redis'

module DataMapper
  module Adapters
    Extlib::Inflection.word 'redis'
    
    class RedisAdapter < AbstractAdapter
      def create(resources)
        resources.each do |resource|
          initialize_identity_field(resource, @redis.incr("#{resource.model}:serial"))
          @redis.set_add("#{resource.model}:all", resource.key)
        end
        
        update_attributes(resources)
      end
      
      def read(query)
        query.filter_records(records_for(query.model)).each do |record|
          query.fields.each do |property|
            record[property.name.to_s] = property.typecast(@redis["#{query.model}:#{record["id"]}:#{property.name}"])
          end
        end
      end
      
      def update(attributes, collection)
        attributes = attributes_as_fields(attributes)
        read(collection.query).each { |r| r.update(attributes) }
      end
      
      def delete(collection)
        collection.query.filter_records(records_for(collection.model)).each do |record|
          collection.query.model.properties.each do |p|
            @redis.delete("#{collection.query.model}:#{record}:#{p}")
          end
          @redis.set_delete("#{collection.query.model}:all", record)
        end
      end
      
      private
      
      def update_attributes(resources)
        resources.each do |resource|
          resource.attributes.each do |property, value|
            @redis["#{resource.model}:#{resource.key}:#{property}"] = value
          end
        end
      end
      
      def records_for(resource)
        # TODO: this needs to work if multiple keys are specified
        @redis.set_members("#{resource}:all").inject([]) do |a, val|
          a << {"#{resource.key.first.name}" => resource.key.first.typecast(val)}
        end
      end
      
      def initialize(name, uri_or_options)
        super
        @redis = Redis.new
        @redis.select_db(@options[:database]) if @options[:database]
      end
    end # class RedisAdapter
    
    const_added(:RedisAdapter)
  end # module Adapters
end # module DataMapper