#! :)

require 'json'

module TrackHub
  class ChIPAtlas
    class Experiments
      def initialize(filepath)
        @filepath = filepath
      end

      def dbarchive_base_url
        "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/eachData"
      end

      def chipatlas_base_url
        "http://chip-atlas.org"
      end

      def export_json
        JSON.dump(read_table)
      end

      def read_table
        tracks = open(@filepath).readlines.map do |line|
          tm = track_metadata(line)
          [
            track_bigwig(tm),
            track_bigbed(tm, "05"),
            track_bigbed(tm, "10"),
            track_bigbed(tm, "20"),
          ]
        end
        tracks.flatten
      end

      def track_bigwig(track_metadata)
        exp_id = track_metadata[:metadata][:experiment_id]
        track_metadata.merge({
          track: exp_id + ".bw",
          type: "bigWig",
          bigDataUrl: File.join(dbarchive_base_url, "bw", exp_id + ".bw"),
        })
      end

      def track_bigbed(track_metadata, threshold)
        exp_id = track_metadata[:metadata][:experiment_id]
        track_metadata.merge({
          track: exp_id + "." + threshold + ".bb",
          type: "bigWig",
          bigDataUrl: File.join(dbarchive_base_url, "bb" + threshold, exp_id + "." + threshold + ".bb"),
        })
      end

      def track_metadata(line)
        items = line.chomp.split("\t")
        ctd = cell_type_desc(items)
        pl = processing_logs(items)
        metadata = submitted_metadata(items)
        {
          shortLabel: items[0],
          longLabel: items[8],
          metadata: {
            experiment_id: items[0],
            genome_assembly: items[1],
            antigen_class: items[2],
            antigen: items[3],
            cell_type_class: items[4],
            cell_type: items[5],
            primary_tissue: ctd[:primary_tissue],
            tissue_diagnosis: ctd[:tissue_diagnosis],
            number_of_reads: pl[:number_of_reads],
            percent_mapped: pl[:percent_mapped],
            percent_duplicated: pl[:percent_duplicated],
            number_of_peaks: pl[:number_of_peaks],
            source_name: metadata["source_name"],
            cell_line: metadata["cell line"],
            chip_antibody: metadata["chip antibody"],
            antibody_catalog_number: metadata["antibody catalog number"],
          },
          visibility: "dense",
          url: File.join(chipatlas_base_url, "view?id=" + items[0]),
        }
      end

      def cell_type_desc(items)
        ctd = items[6].split("|")
        {
          primary_tissue: ctd[0],
          tissue_diagnosis: ctd[1],
        }
      end

      def processing_logs(items)
        pl = items[7].split(",")
        {
          number_of_reads: pl[0],
          percent_mapped: pl[1],
          percent_duplicated: pl[2],
          number_of_peaks: pl[3],
        }
      end

      def submitted_metadata(items)
        h = {}
        items[9..items.size-1].each do |key_value|
          kv = key_value.split("=")
          h[kv[0]] = kv[1]
        end
        h
      end
    end
  end
end
