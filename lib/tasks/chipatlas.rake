require 'fileutils'

namespace :chipatlas do
  explist = ENV['experiment_list']
  metadata_dir = ENV['metadata_dir'] || File.join(PROJ_ROOT, "metadata")

  directory metadata_dir

  file_hub = File.join(metadata_dir, "hub.txt")
  file_genome = File.join(metadata_dir, "genomes.txt")

  task :create => [
    file_hub,
    file_genome,
    :tracks
  ]

  file file_hub do |t|
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

  file file_genome do |t|
    open(t.to_s, 'w') do |file|
      gt = genome_assemblies.map do |g|
        [
          "genome #{g}",
          "trackDb trackDB_#{g}.txt"
        ]
      end
      file.puts(gt.join("\n")+"\n")
    end
  end

  def trackdb_file(metadata_dir, ga)
    File.join(metadata_dir, "trackDb_#{ga}.txt")
  end

  trackdb_files = genome_assemblies.map do |ga|
    trackdb_file(metadata_dir, ga)
  end

  task :tracks => trackdb_files

  genome_assemblies.each do |ga|
    file trackdb_file(metadata_dir, ga) do |t|
      open(t.to_s, "w") do |f|
        f.puts(TrackHub::ChIPAtlas::Track.export(explist, ga))
      end
    end
  end
end
