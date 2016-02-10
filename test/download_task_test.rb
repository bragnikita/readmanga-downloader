require 'minitest/autorun'
require 'minitest/unit'
require 'shoulda'
require 'pathname'
require 'fileutils'
require_relative '../lib/readmanga_dldr'

MD = ReadMangaDownloader

class DownloadTasktest < Minitest::Test
  context 'After initialization' do
    setup do
      @root_dir = Dir.mktmpdir 'manga_root'
      FileUtils.rm_r(@root_dir.to_s+'/*', {:secure => true, :force => true})
      url = 'http://readmanga.me/soredemo_bokura_wa_koi_wo_suru'
      @options = {
          :target_dir => @root_dir.to_s
      }
      @task = MD::DownloadTask.new url, @options
    end

    should 'set root directory for manga' do
      expected_root = File.join @root_dir.to_s, 'soredemo_bokura_wa_koi_wo_suru'
      assert_equal expected_root, @task.title_root_dir.to_path
      assert_equal true, Dir.exist?(@task.title_root_dir)
    end

    should 'create properly file for manga' do
      chapter =MD::ChapterInfo.new 'http://readmanga.me/soredemo_bokura_wa_koi_wo_suru/vol1/3', 1, 3
      image_url = 'http://e4.postfact.ru/auto/15/03/20/01.png_res.jpg'
      order = 1
      file = @task.create_file chapter, image_url, order
      assert_equal true, File.exist?(file)
      expected_file = File.join @root_dir.to_s, 'soredemo_bokura_wa_koi_wo_suru', 'ch3', '01.png_res.jpg'
      assert_equal true, File.identical?(expected_file, file)
    end

    should 'not create new file if exists' do
      chapter =MD::ChapterInfo.new 'http://readmanga.me/soredemo_bokura_wa_koi_wo_suru/vol1/3', 1, 3
      image_url = 'http://e4.postfact.ru/auto/15/03/20/01.png_res.jpg'
      order = 1
      expected_file = File.join @root_dir.to_s, 'soredemo_bokura_wa_koi_wo_suru', 'ch3', '01.png_res.jpg'
      FileUtils.mkpath Pathname.new(expected_file).dirname
      File.new(expected_file, 'wb').close
      file = @task.create_file chapter, image_url, order
      assert_equal true, File.exist?(expected_file)
      assert_nil file
    end

    teardown do
      if @root_dir && Dir.exist?(@root_dir)
        FileUtils.rm_r(@root_dir, {:secure => true, :force => true})
      end
    end

  end


  context 'If downloading' do
    setup do
      @root_dir = Dir.mktmpdir 'manga_root'
      FileUtils.rm_r(@root_dir.to_s+'/*', {:secure => true, :force => true})
      url = 'http://readmanga.me/soredemo_bokura_wa_koi_wo_suru'
      @options = {
          :target_dir => @root_dir.to_s
      }

      @chapter =MD::ChapterInfo.new 'http://readmanga.me/soredemo_bokura_wa_koi_wo_suru/vol1/3', 1, 3
      @image_url = 'http://e6.postfact.ru/auto/15/26/64/01.png'
      @order = 1
      download_handler = OfflineDownloadHandler.new
      download_handler.image_file_path = File.join(Pathname.new(__FILE__).dirname, 'resources/01.png')
      download_handler.image_file_url = @image_url

      @task = MD::DownloadTask.new url, @options, download_handler
    end

    should 'Download and save file' do
      target_file = @task.download_image(@chapter, @order,@image_url)
      p target_file
      assert_equal true, File.exist?(target_file)
    end

    teardown do
      if @root_dir && Dir.exist?(@root_dir)
        FileUtils.rm_r(@root_dir, {:secure => true, :force => true})
      end
    end
  end
end


class OfflineDownloadHandler
  attr_accessor :page_content, :image_file_path, :image_file_url

  def load_page(url)
    Nokogiri::HTML(page_content)
    # Nokogiri::HTML(open(url))
  end

  def load_image(url)
    if image_file_url == url
      File.new(image_file_path, 'rb')
    end
  end
end