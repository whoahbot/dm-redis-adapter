require 'rubygems'
require 'dm-core'
require 'socket'
require 'redis'

module DataMapper
  module Adapters
    Extlib::Inflection.word 'redis'
    
    class RedisAdapter < AbstractAdapter
      @@redis = Redis.new
      
      def create(resources)
        created = 0
        resources.each do |resource|
          identity_field = resource.model.key(repository.name).detect { |p| p.serial? }
          
          if identity_field
            identity_field.set!(resource, @@redis.incr("#{resource.model}:serial"))
            created += 1
          end
          
          resource.dirty_attributes.each do |property, value|
            property.set!(resource, value)
            @@redis["#{resource.model}:#{resource.id}:#{property.name}"] = value
          end
        end
        created
      end
    end # class RedisAdapter
  end # module Adapters
end # module DataMapper