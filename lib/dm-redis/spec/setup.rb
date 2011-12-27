require 'dm-redis'
require 'dm-core/spec/setup'

module DataMapper
  module Spec
    module Adapters

      class RedisAdapter < Adapter
        def connection_uri
          { :adapter  => "redis", :db => 15 }
        end
      end

      use RedisAdapter
    end
  end
end
