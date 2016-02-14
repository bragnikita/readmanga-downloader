Gem::Specification.new do |s|
  s.name = 'readmanga_downloader'
  s.version = '0.0.1'
  s.platform = Gem::Platform::RUBY
  s.date = '2016-02-09'
  s.summary = 'readmanga.me downloader utility'
  s.description = 'Description'
  s.authors = ['Bragnikita']
  s.email = 'bragnikita@mail.ru'
  s.files = Dir['lib/**/*.rb'] + Dir['test/**/*'] + Dir['bin/*']
  s.executables << 'readmanga'
  s.license = 'MIT'
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_development_dependency 'shoulda','= 3.5.0'
end