# Rakefile for TrackHub metadata generation

# add current directory and lib directory to load path
$LOAD_PATH << __dir__
$LOAD_PATH << File.join(__dir__, "lib")

require 'lib/trackhub'

PROJ_ROOT = File.expand_path(__dir__)

Dir["#{PROJ_ROOT}/lib/tasks/**/*.rake"].each do |path|
  load path
end

namespace :registry do
  desc "Request authentication token"
  task :request do
    Rake::Task["registry:request_token"].invoke
  end
end

namespace :trackhub do
  desc "Create Track Hub metadata for each tracks of ChIP-Atlas"
  task :chipatlas do
    Rake::Task["chipatlas:publish"].invoke
  end
end
