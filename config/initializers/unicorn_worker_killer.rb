require 'unicorn/worker_killer'

EdoPersonalCloud::Application.configure do
  config.middleware.use Unicorn::WorkerKiller::MaxRequests, 3072, 4096
  config.middleware.use Unicorn::WorkerKiller::Oom, (1 * (1024 ** 2)), (2 * (1024 ** 2))
end
