require 'rubygems'
require 'dm-core'
require 'redis'

module DataMapper
  module Adapters
    Extlib::Inflection.word 'redis'
    
    class RedisAdapter < AbstractAdapter
      def create(resources)
        resources.each do |resource|
          resource.model.key.each do |k|
            if k.serial?
              initialize_identity_field(resource, @redis.incr("#{resource.model}:#{k}:serial"))
              @redis.set_add("#{resource.model}:#{redis_key_for(resource.model)}:all", resource.key)
            else
              raise NotImplemented
            end
          end
        end
        
        update_attributes(resources)
      end
      
      def read(query)
        key = redis_key_for(query.model)
        records = records_for(query).each do |record|
          query.fields.each do |property|
            record[property.name.to_s] = property.typecast(@redis["#{query.model}:#{record[key]}:#{property.name}"])
          end
        end
        query.filter_records(records)
      end
      
      def update(attributes, collection)
        attributes = attributes_as_fields(attributes)
        read(collection.query).each { |r| r.update(attributes) }
      end
      
      def delete(collection)
        collection.query.filter_records(records_for(collection.query)).each do |record|
          collection.query.model.properties.each do |p|
            @redis.delete("#{collection.query.model}:#{record[redis_key_for(collection.query.model)]}:#{p.name}")
          end
          @redis.set_delete("#{collection.query.model}:#{redis_key_for(collection.query.model)}:all", record[redis_key_for(collection.query.model)])
        end
      end
      
      private
      
      def redis_key_for(model)
        model.key.collect {|k| k.name}.join(":")
      end
      
      def update_attributes(resources)
        resources.each do |resource|
          resource.attributes.each do |property, value|
            @redis["#{resource.model}:#{resource.key}:#{property}"] = value unless value.nil?
          end
        end
      end
      
      def records_for(query)
        @redis.set_members("#{query.model}:#{redis_key_for(query.model)}:all").inject(Set.new) do |s, val|
          s << {"#{redis_key_for(query.model)}" => query.model.key.first.typecast(val)}
        end
      end
      
      def initialize(name, uri_or_options)
        super
        @redis = Redis.new(@options)
      end
    end # class RedisAdapter
    
    const_added(:RedisAdapter)
  end # module Adapters
end # module DataMapper