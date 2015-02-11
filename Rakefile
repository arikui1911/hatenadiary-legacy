# -*- mode: RUBY -*-
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems'
require 'rubygems/package_task'
require 'shellwords'


task 'default' => 'test'

GEMSPEC = 'hatenadiary.gemspec'
LIBS    = FileList["lib/*.rb"]
TESTS   = FileList["test/test_*.rb"]
README  = "README"


gemspec = Gem::Specification.new do |s|
  s.name              = "hatenadiary"
  s.version           = "0.0.7"
  s.authors           = ["arikui"]
  s.date              = "2015-02-11"
  s.description       = "A client for Hatena Diary to post and delete blog entries."
  s.summary           = "It is a library provides a client for Hatena Diary to post and delete blog entries."
  s.email             = "arikui.ruby@gmail.com"
  s.homepage          = "http://wiki.github.com/arikui1911/hatenadiary-legacy"

  s.add_runtime_dependency 'mechanize', '~> 0'
  s.add_development_dependency "test-unit"
  s.add_development_dependency "flexmock"

  etc = [README, "LICENSE", "ChangeLog"]

  s.test_files = TESTS
  s.extra_rdoc_files = etc
  s.files = LIBS + TESTS + etc

  s.rdoc_options = ["--title", "hatenadiary-legacy documentation",
                    "--opname", "index.html",
                    "--line-numbers",
                    "--main", README,
                    "--inline-source"]
end

packager = Gem::PackageTask.new(gemspec)
packager.define

task 'push' => 'gem' do |t|
  gem "push #{packager.package_dir}/#{gemspec.file_name}"
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


