
namespace :server do
  task :start  do
    load 'lib/scripts/server.rb';
    # Thread.new{ sleep 2; `curl -v -k https://localhost:8080` }
    start_server
  end
end