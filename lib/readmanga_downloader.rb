#encoding: utf-8
require 'nokogiri'
require 'uri'
require 'open-uri'
module ReadMangaDownloader

  def self.split_work(values, portion_size)
    values_total = values.length
    res = []
    full_portions = values_total / portion_size
    full_portions += 1 if full_portions == 0
    full_portions += 1 if values_total%portion_size!=0
    (0..full_portions-1).each { |i| res << values[i*portion_size..(i+1)*portion_size-1] }
    res
  end

  class DownloadTask
    attr_reader :started, :params, :title_root_dir, :base_uri

    def initialize(url = nil, params = {}, download_handler = nil)
      url = url || params[:base_url]
      if url.nil?
        raise 'Invalid arguments: base url is not specified'
      end
      @base_uri = URI.parse url
      @params = params
      @parser = MangaReaderParser.new @base_uri
      @title_root_dir = get_or_create_root_dir(@parser.basename)
      @download_handler = download_handler || DownloadHandler.new
      @parser.download_handler = @download_handler
      @filter = ChaptersFilters::ComboFilter.new(params[:filter])
      @started = false
    end

    def start
      @started = true
      all_chapters = @parser.chapters_info
      log "#{all_chapters.length} chapters found"
      @chapters = filter_chapters all_chapters
      log "#{@chapters.length} chapters after filtering"
      download_chapters @chapters
      log 'Finished'
    end

    def download_chapters(chapters)
      threads_count = 5
      portions = ReadMangaDownloader::split_work(chapters, threads_count)
      portions.each do |portion|
        log "Loading chapters #{portion}"
        @threads = portion.map { |chapter|
          Thread.new(chapter) do |ch|
            download_chapter ch
          end
        }
        @threads.each { |thread| thread.join }
      end
    end


    def download_chapter(chapter)
      #TODO We can parallelise our downloads here
      log "ch[#{chapter.chapter}] loading started"
      @parser.images_info(chapter.url).each_with_index do |image_link, index|
        file = download_image chapter, index+1, image_link
        log "ch[#{chapter.chapter}] page[#{index+1}] saved as #{file} "
        sleep 0.5
      end
      log "ch[#{chapter.chapter}] has been fully downloaded"
    end

    def download_image(chapter, order, url)
      begin
        target_file = create_file(chapter, url, order)
        return if target_file.nil?
        net_image = @download_handler.load_image(url)
        IO::copy_stream(net_image, target_file)
      ensure
        net_image && net_image.close
        target_file && target_file.close
      end
      target_file.to_path
    end

    def create_file(chapter, url, order)
      filename = URI.parse(url).path.split('/').compact.last
      ch = File.join @title_root_dir.path, "ch#{chapter.chapter}"
      # vol = "#{chapter.volume}
      Dir.mkdir ch unless Dir.exist? ch
      target = File.join(ch, filename)
      return nil if File.exist? target
      File.new(File.join(ch, filename), 'wb')
    end

    def filter_chapters(chapters)
      chapters.select { |ch| @filter.match? ch.chapter }
    end

    private
    def get_or_create_root_dir(basename)
      manga_base_dir = @params[:target_dir]
      if manga_base_dir.nil?
        manga_base_dir=__FILE__
      end
      dir = File.join manga_base_dir, basename
      unless Dir.exist? dir
        Dir.mkdir dir
      end
      Dir.new dir
    end

    def log(msg)
      puts msg
    end

  end

  module ChaptersFilters
    class Filter
      def match?(chapter_number)
      end
    end

    class Interval < Filter
      def self.is_filter(value)
        /^(\d*\-\d+)|(\d+\-\d*)$/=~value
      end

      def initialize(value)
        m = /^(\d*)\-(\d*)$/.match value
        left = (Integer(m[1]) unless m[1].to_s.empty?) || 0
        right = (Integer(m[2]) unless m[2].to_s.empty?) || 10000
        @range = left..right
      end

      def match?(chapter_number)
        @range === chapter_number
      end

    end
    class Single < Filter
      def self.is_filter(value)
        /^\d+$/.match value
      end

      def initialize(value)
        @value = Integer(value)
      end

      def match?(chapter_number)
        chapter_number == @value
      end
    end

    class ComboFilter < Filter
      def initialize(filter_str)
        @filters = []
        if filter_str.nil? || filter_str.strip.empty?
          @filters << AnyPassFilter.new
        else
          filter_str.split(',').
              compact.select { |f| !f.empty? }.map { |f| f.strip }.each do |f|
            if Single.is_filter f
              @filters << Single.new(f)
            elsif Interval.is_filter f
              @filters << Interval.new(f)
            else
              raise "Incorrect filter element: '#{f}'"
            end
          end
        end
      end

      class AnyPassFilter < Filter
        def match?(value)
          true
        end
      end

      def match?(value)
        @filters.any? { |f| f.match? value }
      end
    end

  end

  class MangaReaderFacade
    # Download info about all chapters of the selected manga
    def chapter_info(manga_url)
      {}
    end

    # Download all chapter links
    def image_links(chapter_url)

      {}
    end

    # Download image
    def image(image_url)

      []
    end

  end

  class MangaReaderParser
    attr_accessor :download_handler
    attr_reader :basename

    def initialize(manga_url)
      @download_handler = DownloadHandler.new
      @manga_uri = manga_url.is_a?(URI) ? manga_url : URI.parse(manga_url)
      @basename = basename
    end

    def chapters_info
      nokogiri = @download_handler.load_page @manga_uri.to_s
      nokogiri.css('div.chapters-link a').map {
          |a| a['href'] if /\/#{@basename}\//.match a['href']
      }.compact.map { |path|
        m = /vol(\d+)\/(\d+)$/.match path
        ChapterInfo.new(
            "http://#{@manga_uri.host}#{path}",
            Integer(m[1]),
            Integer(m[2])
        )
      }.sort
    end

    def images_info(chapter_page_url)
      nokogiri = @download_handler.load_page chapter_page_url.to_s
      script_content = nokogiri.css('div.pageBlock.container.reader-bottom script')
                           .map { |node| node.content }
                           .select { |script_content| /var transl_next_page/m =~ script_content && /rm_h\.init/m =~ script_content }
                           .first
      raise "Pages info was not found in [#{chapter_page_url}]. Looks like current program is deprecated =(" unless script_content
      extract_links script_content
    end

    def extract_links(script_text)
      links_str = script_text.slice(/rm_h\.init\(\s*\[\[(.*?)\]\]/m, 1)
      link_blocks = links_str.split(/\],\[/m)
      res = []
      link_blocks.each do |block|
        values = block.split(',')
        res << [
            values[1][1..-2],
            values[0][1..-2],
            values[2][1..-2]
        ].join
      end
      res
    end

    def basename
      @manga_uri.path.split('/').compact[1]
    end
  end

  class DownloadHandler
    def load_page(url)
      Nokogiri::HTML(open(url))
    end

    def load_image(url)
      open url
    end
  end

  class ChapterInfo
    attr_accessor :url, :volume, :chapter

    def initialize(url, volume=1, chapter=1)
      @url = url
      @volume = volume
      @chapter = chapter
    end

    # На ридманге нумерация глав сквозная, так что тома не нужны
    def <=>(chapter)
      @chapter <=> chapter.chapter
    end
  end
end