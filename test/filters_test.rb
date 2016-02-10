require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/expectations'
require 'open-uri'
require 'shoulda'
require_relative '../lib/readmanga_dldr'
class FiltersTest < Minitest::Test
  def initialize(name)
    super name
    @filter1='1,2,5, 4,2, 8'
    @filter2='-3,5-8,10-,7'
  end

  context 'Initialized' do
    setup do

    end

    should 'set current directory as root'
    should 'set specified directory as root'
  end

  context 'When filter #1 was set' do
    setup { @filter = ReadMangaDownloader::ChaptersFilters::ComboFilter.new(@filter1) }
    should('1 includes') do
      assert_equal true, (@filter.match? 1)
    end
    should('3 not includes') { assert_equal false, (@filter.match? 3) }
    should('2 includes') { assert_equal true, (@filter.match? 2) }
  end

  context 'When filter #2 was set' do
    setup { @filter = ReadMangaDownloader::ChaptersFilters::ComboFilter.new(@filter2) }
    should ('1 includes') { assert_equal true, (@filter.match? 1) }
    should '4 not includes' do
      assert_equal false, @filter.match?(4)
    end
    should '5 includes' do
      assert_equal true, @filter.match?(5)
    end
    should '100 includes' do
      assert_equal true, @filter.match?(100)
    end
    should '10 includes' do
      assert_equal true, @filter.match?(10)
    end
    should '9 not includes' do
      assert_equal false, @filter.match?(9)
    end

  end
  context 'When incorrect filter line provided' do
    should 'create all-pass filter for empty line' do
      @filter = ReadMangaDownloader::ChaptersFilters::ComboFilter.new ' '
      assert_equal true, @filter.match?(5)
    end
    should 'raise parsing exception on wrong line' do
      ['5, 4,1,-', 'a,3,1', '7;43,4'].each do |filter|
        assert_raises {ReadMangaDownloader::ChaptersFilters::ComboFilter.new filter}
      end
    end
  end
  context 'Other functions' do
    should 'split properly' do
      task = [1,2,3,4,5,6,7,8,9,10,11,12]
      expected = [[1,2,3,4,5],[6,7,8,9,10],[11,12]]
      assert_equal expected, ReadMangaDownloader::split_work(task, 5)
    end
  end
end