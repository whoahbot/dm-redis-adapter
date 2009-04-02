require 'rubygems'
require 'dm-core'
require 'socket'
require 'redis'

module DataMapper
  module Adapters
    Extlib::Inflection.word 'redis'
    
    class RedisAdapter < AbstractAdapter
      def initialize(name, uri_or_options)
        super
        @redis = Redis.new
        @redis.select_db(@options[:database]) if @options[:database]
      end

      def create(resources)
        records = records_for(resources.first.model)
        
        resources.each do |resource|
          initialize_identity_field(resource, @redis.incr("#{resource.model}:serial"))
          @redis.set_add("#{resource.model}:all", resource.key.to_s)
          update_attributes(resource, resource.attributes)
        end
      end
      
      def read(query)
        model = query.model
        
        records = records_for(model)
        filter_records(records, query)
      end
      
      def update(attributes, collection)
        model = collection.model
        query = collection.query
        
        
        records    = records_for(model)
        attributes = attributes_as_fields(attributes)
        # attributes = attributes.map { |p,v| [ p.name, v ] }.to_hash
        
        updated = filter_records(records, query)
        updated.each { |r| r.update(attributes) }
      end
      
      def delete(collection)
        model = collection.model
        query = collection.query
        
        records = records_for(model)
        deleted = filter_records(records, query).map do |record|
          query.model.properties.each do |p|
            @redis.delete("#{query.model}:#{record}:#{p}")
          end
          @redis.set_delete("#{query.model}:all", record)
        end
        deleted.size
      end
      
      private
      
      def sort_records(records, query)
        records
      end
      
      def update_attributes(resource, attributes)
        attributes.each do |property, value|
          @redis["#{resource.model}:#{resource.key}:#{property}"] = value
        end
      end
      
      def records_for(model)  
        @redis.set_members("#{model}:all").to_a
      end
    end # class RedisAdapter
    const_added(:RedisAdapter)
  end # module Adapters
end # module DataMapper