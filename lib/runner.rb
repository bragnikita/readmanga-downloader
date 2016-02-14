require 'pathname'
require 'fileutils'
require 'uri'
require 'optparse'
require 'ostruct'
require_relative 'readmanga_downloader'

module ReadMangaDownloader
  class Runner
    def self.get_default_file
      Pathname(Dir.pwd).each_entry do |file|
        if File.file?(file) && File.basename(file) == 'manga.txt'
          return file.to_path
        end
      end
      raise 'Task description file was not found in current directory'
    end

    def self.read_params_file(source_file)
      File.open(source_file, 'r') do |io|
        lines = io.readlines.compact.select { |line| !line.empty? }.map { |line| line.strip }
        [lines[0], lines[1]]
      end
    end

    def self.parse_options(args)
      options = OpenStruct.new
      options.manga_root = 'manga_root'
      options.test_mode = false
      opts_parser = OptionParser.new do |opts|
        opts.banner = 'Readmanga Downloader. Downloads manga chapters as images from readmanga.me'
        opts.define_head 'Usage: readmanga [options]'
        opts.separator ''
        opts.separator 'Examples:'
        opts.separator 'Calling without options cause looking for file \'manga.txt\' where ' +
                           ' manga page url and filter (optional) are specified'
        opts.separator '  readmanga'
        opts.separator '  readmanga -url http://readmanga.me/puella_magi_madoka_magica___wraith_arc'
        opts.separator '  readmanga -f 3-6,8'
        opts.separator '  readmanga -url http://readmanga.me/puella_magi_madoka_magica___wraith_arc -f 3-'
        opts.separator 'Specific options'

        opts.on('-t', '--task FILENAME', 'Specifies file with manga url and filter string (default is manga.txt)') do |file|
          url, filter = read_params_file file
          options.url = url
          options.filter = filter
          options.loaded_from_file = true
        end

        opts.on('-u', '--url URL', 'Specifies manga main page url on readmanga.me') do |url|
          options.url = url
        end
        opts.on('-f', '--filter FILTER_STRING', 'Chapter filter string') do |filter|
          options.filter = filter
        end
        opts.on('-d', '--dest DIRECTORY', 'Manga titles root directory',
                "Titles will be downloaded into this directory. Default is #{options.manga_root}") do |dir|
          options.manga_root = dir
        end
        opts.on('-t', '--test', 'Only print provided parameters') do
          options.test_mode = true
        end
      end
      opts_parser.parse! args
      if options.url == nil
        unless options.loaded_from_file
          url, filter = read_params_file 'manga.txt'
          options.url = url
          options.filter = filter if options.filter == nil
        end
      end
      options
    end

    def run(args)
      options = ReadMangaDownloader::Runner.parse_options args
      source_url = options.url
      filter_str = options.filter
      repo_root = options.manga_root
      FileUtils.mkpath repo_root unless Dir.exist? repo_root

      options_hash = {
          :base_url => source_url,
          :target_dir => repo_root,
          :filter => filter_str,
      }
      if options.test_mode
        p "Manga page url: #{options_hash[:base_url]}"
        p "Manga repository root: #{options_hash[:target_dir]}"
        p "Chapters filter: #{options_hash[:filter]}"
      else
        download_task = ReadMangaDownloader::DownloadTask.new(nil, options_hash)
        download_task.start
      end
    end
  end
end