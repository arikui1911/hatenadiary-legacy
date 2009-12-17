# -*- mode: RUBY -*-
require 'rubygems'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'shellwords'


task 'default' => 'test'

GEMSPEC = 'hatenadiary.gemspec'
LIBS    = FileList["lib/*.rb"]
TESTS   = FileList["test/test_*.rb"]
README  = "README"


gemspec = Gem::Specification.new do |s|
  s.name              = "hatenadiary"
  s.version           = "0.0.5"
  s.authors           = ["arikui"]
  s.date              = "2009-12-18"
  s.rubyforge_project = "hatenadiary"
  s.description       = "A client for Hatena Diary to post and delete blog entries."
  s.summary           = "It is a library provides a client for Hatena Diary to post and delete blog entries."
  s.email             = "arikui.ruby@gmail.com"
  s.homepage          = "http://wiki.github.com/arikui1911/hatenadiary"
  
  s.add_dependency "mechanize"
  s.add_dependency "nokogiri", ">= 1.3.3"
  
  etc = [README, "LICENSE", "ChangeLog"]
  
  s.test_files = TESTS
  s.extra_rdoc_files = etc
  s.files = LIBS + TESTS + etc
  
  s.rdoc_options = ["--title", "hatenadiary documentation",
                    "--opname", "index.html",
                    "--line-numbers",
                    "--main", README,
                    "--inline-source"]
end


gem_task = Rake::GemPackageTask.new(gemspec)
gem_task.define
gem_dest = "#{gem_task.package_dir}/#{gem_task.gem_file}"


desc "Upload the gem file #{gem_task.gem_file} to GemCutter"
task 'cutter' => 'gem' do |t|
  gem "push #{gem_dest}"
end


Rake::TestTask.new do |t|
  t.test_files = TESTS
end


Rake::RDocTask.new do |t|
  t.rdoc_dir = 'doc'
  t.rdoc_files = LIBS.include(README)
  t.options.push '-S', '-N'
end


desc "Update #{GEMSPEC}"
task "gemspec" do
  cp GEMSPEC, "#{GEMSPEC}~" if File.exist?(GEMSPEC)
  code = gemspec.to_ruby.sub(/\A#.*$/, '').strip  # remove utf8 magic encoding which hard-coded
  File.open(GEMSPEC, 'w'){|f| f.puts code }
end


