namespace :chipatlas do
  explist = ENV['experiment_list']

  task :create do
    puts TrackHub::ChIPAtlas::Experiments.new(explist).export_json
  end
end
