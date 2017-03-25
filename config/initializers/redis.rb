# Initialize redis config
Rails.application.config.redis = {
  host: 'redis',
  port: 6379,
  db: 15
}

# Initialize redis object
$redis = Redis.new Rails.application.config.redis unless Rails.env.production?
$redis = Redis.new ENV['REDIS_URL'] if Rails.env.production?
