# Monkey-patch Resque to work with `redis://` URLs properly by porting the version of the
# `redis=` method from their (unreleased) master branch.
module Resque
  # Accepts:
  #   1. A 'hostname:port' String
  #   2. A 'hostname:port:db' String (to select the Redis db)
  #   3. A 'hostname:port/namespace' String (to set the Redis namespace)
  #   4. A Redis URL String 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
  #      or `Redis::Namespace`.
  #   6. An Hash of a redis connection {:host => 'localhost', :port => 6379, :db => 0}
  def redis=(server)
    case server
    when String
      if server =~ /redis\:\/\//
        redis = Redis.new(:url => server, :thread_safe => true)  # This is the line that has changed!
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(:host => host, :port => port,
          :thread_safe => true, :db => db)
      end
      namespace ||= :resque

      @data_store = Resque::DataStore.new(Redis::Namespace.new(namespace, :redis => redis))
    when Redis::Namespace
      @data_store = Resque::DataStore.new(server)
    when Resque::DataStore
      @data_store = server
    when Hash
      @data_store = Resque::DataStore.new(Redis::Namespace.new(:resque, :redis => Redis.new(server)))
    else
      @data_store = Resque::DataStore.new(Redis::Namespace.new(:resque, :redis => server))
    end
  end
end
# End monkey-patch

Resque.redis = ENV.fetch('REDIS_URL', 'localhost:6379')
