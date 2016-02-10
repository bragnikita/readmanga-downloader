require 'pathname'
require 'fileutils'
require 'uri'
require_relative 'readmanga_downloader'

module ReadMangaDownloader
  class Runner
    def get_default_file
      Pathname(Dir.pwd).each_entry do |file|
        if File.file?(file) && File.basename(file) == 'manga.txt'
          return file.to_path
        end
      end
      raise 'Task description file was not found in current directory'
    end

    def read_params_file(source_file)
      File.open(source_file, 'r') do |io|
        lines = io.readlines.compact.select { |line| !line.empty? }.map { |line| line.strip }
        [lines[0], lines[1]]
      end
    end

    def run(args)

      source_url, source_file, filter_str = nil
      if args.empty?
        source = get_default_file
      elsif args.length == 1
        source = args[0]
      else
        source = args[0]
        filter_str = args[1]
      end
      begin
        if %w(http https).include? URI.parse(source).scheme
          source_url = source
        else
          source_file = source
        end
      rescue URI::InvalidURIError
        source_file = source
      end
      if source_file
        source_url, filter_str = read_params_file(source_file)
      end

      repo_root = File.join(Dir.pwd, 'manga_root')
      FileUtils.mkpath repo_root unless Dir.exist? repo_root

      options = {
          :base_url => source_url,
          :target_dir => repo_root,
          :filter => filter_str,
      }
      p "Manga page url: #{options[:base_url]}"
      p "Manga repository root: #{options[:target_dir]}"
      p "Chapters filter: #{options[:filter]}"
# download_task = ReadMangaDownloader::DownloadTask.new(nil, options)
#download_task.start
    end
  end
end