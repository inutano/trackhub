namespace :chipatlas do
  explist = ENV['experiment_list']

  task :create do
    puts TrackHub::ChIPAtlas::Experiments.export_trackfile(explist)
  end
end
