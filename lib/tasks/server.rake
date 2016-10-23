
namespace :server do
  task :start  do
    load 'lib/scripts/server.rb';
    start_server( secure:true, port:8080 )
  end
end