require 'redis'

module DataMapper
  module Adapters
    Extlib::Inflection.word 'redis'
    
    class RedisAdapter < AbstractAdapter
      ##
      # Used by DataMapper to put records into the redis data-store: "INSERT" in SQL-speak.
      # It takes an array of the resources (model instances) to be saved. Resources
      # each have a key that can be used to quickly look them up later without
      # searching.
      #
      # @param [Enumerable(Resource)] resources
      #   The set of resources (model instances)
      #
      # @api semipublic
      def create(resources)
        resources.each do |resource|
          initialize_identity_field(resource, @redis.incr("#{resource.model.to_s.downcase}:#{redis_key_for(resource.model)}:serial"))
          @redis.set_add("#{resource.model.to_s.downcase}:#{redis_key_for(resource.model)}:all", resource.key)
        end
        
        update_attributes(resources)
      end
      
      ##
      # Looks up one record or a collection of records from the data-store:
      # "SELECT" in SQL.
      #
      # @param [Query] query
      #   The query to be used to seach for the resources
      #
      # @return [Array]
      #   An Array of Hashes containing the key-value pairs for
      #   each record
      #
      # @api semipublic
      def read(query)
        records = records_for(query).each do |record|
          query.fields.each do |property|
            next if query.model.key.include?(property.name)
            record[property.name.to_s] = property.typecast(@redis["#{query.model.to_s.downcase}:#{record[redis_key_for(query.model)]}:#{property.name}"])
          end
        end

        records = query.match_records(records)
        records = query.limit_records(records)
        records = query.sort_records(records)
        records
      end
      
      ##
      # Used by DataMapper to update the attributes on existing records in the redis
      # data-store: "UPDATE" in SQL-speak. It takes a hash of the attributes
      # to update with, as well as a collection object that specifies which resources
      # should be updated.
      #
      # @param [Hash] attributes
      #   A set of key-value pairs of the attributes to update the resources with.
      # @param [DataMapper::Collection] collection
      #   The collection object that should be used to find the resource(s) to update.
      #
      # @api semipublic
      def update(attributes, collection)
        attributes = attributes_as_fields(attributes)
        
        records_to_update = records_for(collection.query)
        records_to_update.each { |r| r.update(attributes) }
        update_attributes(collection)
      end
      
      ##
      # Destroys all the records matching the given query. "DELETE" in SQL.
      #
      # @param [DataMapper::Collection] collection
      #   The query used to locate the resources to be deleted.
      #
      # @return [Array]
      #   An Array of Hashes containing the key-value pairs for
      #   each record
      #
      # @api semipublic
      def delete(collection)
        collection.query.filter_records(records_for(collection.query)).each do |record|
          collection.query.model.properties.each do |p|
            @redis.delete("#{collection.query.model.to_s.downcase}:#{record[redis_key_for(collection.query.model)]}:#{p.name}")
          end
          @redis.set_delete("#{collection.query.model.to_s.downcase}:#{redis_key_for(collection.query.model)}:all", record[redis_key_for(collection.query.model)])
        end
      end
      
      private
      
      ##
      # Creates a string representation for the keys in a given model
      #
      # @param [DataMapper::Model] model
      #   The query used to locate the resources to be deleted.
      #
      # @return [Array]
      #   An Array of Hashes containing the key-value pairs for
      #   each record
      #
      # @api private
      def redis_key_for(model)
        model.key.collect {|k| k.name}.join(":")
      end
      
      ##
      # Saves each key value pair to the redis data store
      #
      # @param [Array] resources
      #   An array of resources to save
      #
      # @api private
      def update_attributes(resources)
        resources.each do |resource|
          resource.attributes.each do |property, value|
            next if resource.key.include?(property)
            @redis["#{resource.model.to_s.downcase}:#{resource.key}:#{property}"] = value unless value.nil?
          end
        end
      end
      
      ##
      # Retrieves records for a particular model.
      #
      # @param [DataMapper::Query] query
      #   The query used to locate the resources
      #
      # @return [Array]
      #   An array of hashes of all of the records for a particular model
      #
      # @api private
      def records_for(query)
        keys = []
        query.conditions.operands.select {|o| o.is_a?(DataMapper::Query::Conditions::EqualToComparison) && query.model.key.include?(o.subject)}.each do |o|
          if @redis.set_member?("#{query.model.to_s.downcase}:#{redis_key_for(query.model)}:all", o.value)
            keys << {"#{redis_key_for(query.model)}" => o.value}
          end
        end
        
        # if query.limit
        #   @redis.sort("#{query.model.to_s.downcase}:#{redis_key_for(query.model)}:all", :limit => [query.offset, query.limit]).each do |val|
        #     keys << {"#{redis_key_for(query.model)}" => val.to_i}
        #   end
        # end
        
        # Keys are empty, fall back and load all the values for this model
        if keys.empty?
          @redis.set_members("#{query.model.to_s.downcase}:#{redis_key_for(query.model)}:all").each do |val|
            keys << {"#{redis_key_for(query.model)}" => val.to_i}
          end
        end
        
        keys
      end

      ##
      # Make a new instance of the adapter. The @redis ivar is the 'data-store'
      # for this adapter.
      #
      # @param [String, Symbol] name
      #   The name of the Repository using this adapter.
      # @param [String, Hash] uri_or_options
      #   The connection uri string, or a hash of options to set up
      #   the adapter
      #
      # @api semipublic
      def initialize(name, uri_or_options)
        super
        @redis = Redis.new(@options)
      end
    end # class RedisAdapter
    
    const_added(:RedisAdapter)
  end # module Adapters
end # module DataMapper