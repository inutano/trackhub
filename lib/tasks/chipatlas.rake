require 'fileutils'
require 'open-uri'

namespace :chipatlas do
  desc "Create Track Hub metadata for each tracks of ChIP-Atlas and ship it"
  task :publish => [
    :fetch,
    :create,
    :upload,
  ]

  #
  # fetch data from chip-atlas.org
  #

  data_dir = ENV['data_dir'] || File.join(PROJ_ROOT, "data", Time.now.strftime("%Y-%m-%d"))
  directory data_dir

  bigfile_ls = ENV['bigfile']

  experiment_list = File.join(data_dir, "experimentList.tab")
  bigfile_list = File.join(data_dir, "chipatlas.available.txt")

  task :fetch => [
    experiment_list,
    bigfile_list,
  ]

  file experiment_list => data_dir do |t|
    url = "http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/experimentList.tab"
    open(t.name, 'w'){|file| file.puts(open(url).read) }
  end

  file bigfile_list => data_dir do |t|
    `cat #{bigfile_ls} | awk '$0 ~ /.(bb|bw)$/ && $5 != "667" { print $10 }' > #{t.name}`
  end

  #
  # create datahub metadata files
  #

  metadata_dir = ENV['metadata_dir'] || File.join(PROJ_ROOT, "metadata")
  directory metadata_dir

  file_hub = File.join(metadata_dir, "hub.txt")
  file_genome = File.join(metadata_dir, "genomes.txt")

  task :create => [
    file_hub,
    file_genome,
    :tracks
  ]

  file file_hub => metadata_dir do |t|
    cont = {
      hub: "ChIP-Atlas",
      shortLabel: "ChIP-Atlas",
      longLabel: "ChIP-Atlas",
      genomesFile: "genomes.txt",
      email: "t.ohta@dbcls.rois.ac.jp",
      descriptionUrl: "http://chip-atlas.org/",
    }
    open(t.to_s, 'w'){|f| f.puts(cont.map{|k,v| k.to_s + "\s" + v }) }
  end

  genome_assemblies = [
    "hg19",
    "mm9",
    "ce10",
    "dm3",
    "sacCer3"
  ]

  def trackdb_filename(ga)
    "trackDb_#{ga}.txt"
  end

  def trackdb_filepath(metadata_dir, ga)
    File.join(metadata_dir, ga, trackdb_filename(ga))
  end

  file file_genome => metadata_dir do |t|
    open(t.to_s, 'w') do |file|
      gt = genome_assemblies.map do |ga|
        [
          "genome #{ga}",
          "trackDb #{ga}/#{trackdb_filename(ga)}\n",
        ]
      end
      file.puts(gt.join("\n"))
    end
  end

  task :tracks => genome_assemblies.map{|ga| trackdb_filepath(metadata_dir, ga) }

  genome_assemblies.each do |ga|
    genome_dir = File.join(metadata_dir, ga)
    directory genome_dir
    file trackdb_filepath(metadata_dir, ga) => genome_dir do |t|
      open(t.to_s, "w") do |f|
        f.puts(TrackHub::ChIPAtlas::Track.export(experiment_list, ga, bigfile_list))
      end
    end
  end

  #
  # upload file to data.dbcls.jp
  #

  task :upload do
    server = ENV['server'] || "web05"
    remote_dir = ENV['remote_dir'] || 'public_html/trackhub/chip-atlas'
    `ssh #{server} mkdir -p #{remote_dir}`
    `rsync -avr #{metadata_dir}/ #{server}:#{remote_dir}`
  end
end
