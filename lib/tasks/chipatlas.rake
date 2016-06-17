require 'fileutils'

namespace :chipatlas do
  explist = ENV['experiment_list']
  metadata_dir = ENV['metadata_dir'] || File.join(PROJ_ROOT, "metadata")

  task :create do
    ["hg19", "mm9", "ce10", "dm3", "sacCer3"].each do |g|
      open(File.join(metadata_dir, "trackDb_#{g}.txt")) do |f|
        f.puts(TrackHub::ChIPAtlas::Track.export(explist, g))
      end
    end
  end
end
