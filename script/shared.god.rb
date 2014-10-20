GOD_SETTINGS = YAML.load_file("#{RAILS_ROOT}/config/god.yml")
GOD_DEFAULT_OPTIONS = {
  :start_grace => 10.seconds,
  :stop_grace => 10.seconds,
  :restart_grace => 10.seconds,
  :cpu_interval => 60.seconds,
  :cpu_limit => 30.percent,
  :memory_interval => 60.seconds,
  :memory_limit => 200.megabytes,
  :contact => "edo_pds_developers",
}

def set_default_email_sender(god_task_name)
  God::Contacts::Email.defaults do |d|
    d.from_email = GOD_SETTINGS["from_email"][RAILS_ENV]
    d.from_name = "edo_pds_#{god_task_name}_monitoring"
    d.delivery_method = :sendmail
  end

  God.contact(:email) do |c|
    c.name = GOD_SETTINGS["notify_receiver"]
    c.to_email = GOD_SETTINGS["to_email"][RAILS_ENV]
  end
end

def set_default_watching(w)
  w.dir = RAILS_ROOT
  w.interval = 30.seconds
  w.behavior(:clean_pid_file)
end

def generic_monitoring(w, options = {})
  w.start_grace   = options[:start_grace]
  w.stop_grace    = options[:stop_grace]
  w.restart_grace = options[:restart_grace]

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.notify  = options[:contact]
      c.running = false
    end
  end

  # restart if memory or cpu is too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.interval = options[:memory_interval]
      c.above = options[:memory_limit]
      c.times = [3, 5]
      c.notify  = options[:contact]
    end

    on.condition(:cpu_usage) do |c|
      c.interval = options[:cpu_interval]
      c.above = options[:cpu_limit]
      c.times = [3, 5]
      c.notify  = options[:contact]
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify  = options[:contact]
    end
  end
end
