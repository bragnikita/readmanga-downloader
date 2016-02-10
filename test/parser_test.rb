require 'minitest/autorun'
require 'minitest/unit'
require 'open-uri'
require 'shoulda'
require_relative '../lib/readmanga_dldr'
class ParserTest < Minitest::Test

  context 'When manga page open' do
    setup do
      @page_content = File.open('resources/manga_5_chapters_raw.html', 'r:UTF-8').read
      @parser = ReadMangaDownloader::MangaReaderParser.new('http://readmanga.me/soredemo_bokura_wa_koi_wo_suru')
      download_handler = DownloadHandler.new
      download_handler.page_content = @page_content
      @parser.download_handler = download_handler
    end

    should 'find 5 chapters' do
      chapters_info = @parser.chapters_info
      assert_equal 5, chapters_info.length
    end

    should 'find links for 5 chapters' do
      chapters_info = @parser.chapters_info
      (1..5).each { |i|
        chapter_url = "http://readmanga.me/soredemo_bokura_wa_koi_wo_suru/vol1/#{i}"
        chapter_info = chapters_info[i-1]
        assert_equal chapter_url, chapter_info.url
        assert_equal 1, chapter_info.volume
        assert_equal i, chapter_info.chapter
      }
    end

  end

  context 'When chapter page open' do
    setup do
      @parser = ReadMangaDownloader::MangaReaderParser.new('http://readmanga.me/soredemo_bokura_wa_koi_wo_suru')
      download_handler = DownloadHandler.new
      download_handler.page_content = File.open('resources/manga_2th_chapter.html', 'r:UTF-8').read
      @parser.download_handler = download_handler
      @chapter_url = 'http://readmanga.me/soredemo_bokura_wa_koi_wo_suru/vol1/2'
    end
    should 'do not fail parsing' do
      refute_nil @parser.images_info(@chapter_url)
    end
    should 'find x pages in the 1st chapter' do
      assert_equal 29, @parser.images_info(@chapter_url).length
    end
    should 'get 3 correct links to images of the 1st chapter' do
      first_links = %w(http://e4.postfact.ru/auto/15/03/20/01.png_res.jpg http://e3.postfact.ru/auto/15/03/20/02.png http://e1.postfact.ru/auto/15/03/20/03.png)
      actual_links = @parser.images_info(@chapter_url)[0..2]
      (0..2).each do |i|
        assert_equal first_links[i], actual_links[i]
      end
    end
  end

end

class DownloadHandler
  attr_accessor :page_content

  def load_page(url)
    Nokogiri::HTML(page_content)
    # Nokogiri::HTML(open(url))
  end

  def load_image(url)
    Nokogiri::HTML(page_content)
  end
end