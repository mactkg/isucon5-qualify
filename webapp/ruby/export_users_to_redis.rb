require 'mysql2'
require 'redis'
require 'hiredis'
require "mysql2-cs-bind"

def db
  return @client if @client
  @client = Mysql2::Client.new(
      host: 'localhost',
      port: nil,
      username: 'root',
      password: nil,
      database: 'isucon5q',
      reconnect: true,
      )
  @client.query_options.merge!(symbolize_keys: true)
  @client
end

def redis
  return Thread.current[:isucon5_redis] if Thread.current[:isucon5_redis]
  client = Redis.new(
      host: '127.0.0.1',
      port: '6379',
      driver: :hiredis
  )
  Thread.current[:isucon5_redis] = client
  client
end

def main
  users = db.xquery("select * from users")
  attrs = %w(account_name nick_name email)
  threads = []
  users.each_slice(500).each do |slice|
    threads << Thread.new do
      slice.each do |user|
        attrs.each do |attr|
          redis.hset("user:#{user[:id]}", attr, user[attr.to_sym])
        end
      end
    end
  end
  threads.each {|t| t.join }
end

main()

