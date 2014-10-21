require "#{RAILS_ROOT}/script/shared.god"

set_default_email_sender("redis")

God.watch do |w|
  set_default_watching(w)

  redis_root = "/home/azureuser/redis"

  w.name = "redis"
  w.pid_file = "#{redis_root}/redis.pid"

  w.start = "cd #{redis_root} && #{redis_root}/redis-server #{redis_root}/redis.conf"
  w.stop = "kill -QUIT `cat #{w.pid_file}`"

  options = GOD_DEFAULT_OPTIONS
  generic_monitoring(w, options)
end
