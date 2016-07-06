#! :)

require 'json'

module TrackHub
  class ChIPAtlas
    class Track
      class << self
        def supertrack
          st = ["bigBed", "bigWig"].map do |type|
            [
              "track ChIP-Atlas,#{type}",
              "shortLabel ChIP-Atlas,#{type}",
              "longLabel ChIP-Atlas,#{type}",
              "superTrack on",
            ].join("\n")
          end
          st.join("\n\n")
        end

        def parents(filepath, genome)
          ac_raw = `awk -F '\t' '$2 == "#{genome}" { print $3 "\t" $5 }' #{filepath} | sort -u`
          parents = ac_raw.split("\n").map do |a_c|
            ac = a_c.split("\t")
            a = ac[0].gsub(/\s/,"_")
            c = ac[1].gsub(/\s/,"_")
            ps = ["bigBed", "bigWig"].map do |type|
              name = "#{a},#{c},#{type}"
              [
                "track #{name}",
                "shortLabel #{name}",
                "longLabel #{name}",
                "compositeTrack on",
                "allButtonPair on",
                "type #{type}",
                "autoScale on",
                "maxHeightPixel 100:16:8",
                "parent ChIP-Atlas,#{type}",
              ].join("\n")
            end
            ps.join("\n\n")
          end
          parents.join("\n\n")
        end

        def read_table(filepath, genome)
          tracks = open(filepath).readlines.map do |line|
            track = self.new(line)
            next if track.genome != genome
            [
              track.bigwig,
              track.bigbed("05"),
              track.bigbed("10"),
              track.bigbed("20"),
            ]
          end
          tracks.compact.flatten
        end

        def export_json(filepath, genome)
          JSON.dump(read_table(filepath, genome))
        end

        def export(filepath, genome)
          tracks = read_table(filepath, genome)
          track_lines = tracks.map do |track|
            track_line = track.map do |key, value|
              if value.class == Hash
                val = value.map do |k,v|
                  k.to_s.upcase + "=" + v.gsub(/\s/,"_") if v
                end
                key.to_s + "\s" + val.join("\s")
              else
                key.to_s + "\s" + value
              end
            end
            track_line.join("\n")
          end
          [supertrack, parents(filepath, genome), track_lines.join("\n\n")].join("\n\n")
        end
      end

      def initialize(line)
        @items = line.chomp.split("\t")
        @metadata = metadata
        @exp_id = @metadata[:metadata][:experiment_id]
        @genome = @metadata[:metadata][:genome_assembly]
      end
      attr_reader :genome

      def bigwig
        {
          track: @exp_id + ".bw",
          type: "bigWig",
          bigDataUrl: File.join(dbarchive_base_url, "bw", @exp_id + ".bw"),
          parent: [@items[2].gsub(/\s/,"_"),@items[4].gsub(/\s/,"_"),"bigWig"].join(",") + " on",
        }.merge(@metadata)
      end

      def bigbed(threshold)
        {
          track: @exp_id + "." + threshold + ".bb",
          type: "bigBed",
          bigDataUrl: File.join(dbarchive_base_url, "bb" + threshold, @exp_id + "." + threshold + ".bb"),
          parent: [@items[2].gsub(/\s/,"_"),@items[4].gsub(/\s/,"_"),"bigBed"].join(",") + " on",
        }.merge(@metadata)
      end

      def metadata
        ctd = cell_type_desc
        pl = processing_logs
        sm = submitted_metadata
        {
          shortLabel: @items[0],
          longLabel:  @items[8],
          metadata: {
            experiment_id:   @items[0],
            genome_assembly: @items[1],
            antigen_class:   @items[2],
            antigen:         @items[3],
            cell_type_class: @items[4],
            cell_type:       @items[5],
            primary_tissue:   ctd[:primary_tissue],
            tissue_diagnosis: ctd[:tissue_diagnosis],
            number_of_reads:    pl[:number_of_reads],
            percent_mapped:     pl[:percent_mapped],
            percent_duplicated: pl[:percent_duplicated],
            number_of_peaks:    pl[:number_of_peaks],
            source_name:   sm["source_name"],
            cell_line:     sm["cell line"],
            chip_antibody: sm["chip antibody"],
            antibody_catalog_number: sm["antibody catalog number"],
          },
          visibility: "dense",
          url: File.join(chipatlas_base_url, "view?id=" + @items[0]),
        }
      end

      def cell_type_desc
        ctd = @items[6].split("|")
        {
          primary_tissue: ctd[0],
          tissue_diagnosis: ctd[1],
        }
      end

      def processing_logs
        pl = @items[7].split(",")
        {
          number_of_reads:    pl[0],
          percent_mapped:     pl[1],
          percent_duplicated: pl[2],
          number_of_peaks:    pl[3],
        }
      end

      def submitted_metadata
        h = {}
        @items[9..@items.size-1].each do |key_value|
          kv = key_value.split("=")
          h[kv[0]] = kv[1]
        end
        h
      end

      def dbarchive_base_url
        "http://dbarchive.biosciencedbc.jp/kyushu-u/#{@genome}/eachData"
      end

      def chipatlas_base_url
        "http://chip-atlas.org"
      end
    end
  end
end
