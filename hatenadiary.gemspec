

Gem::Specification.new do |s|
  s.name = %q{hatenadiary}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["arikui"]
  s.date = %q{2009-06-22}
  s.description = %q{A client for Hatena Diary to post and delete blog entries.}
  s.email = %q{arikui.ruby@gmail.com}
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["README", "LICENSE", "Rakefile", "test/test_hatenadiary.rb", "lib/hatenadiary.rb"]
  s.homepage = %q{http://wiki.github.com/arikui1911/hatenadiary}
  s.rdoc_options = ["--title", "hatenadiary documentation", "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source", "--exclude", "^(examples|extras)/"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{hatenadiary}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{It is a library provides a client for Hatena Diary to post and delete blog entries.}
  s.test_files = ["test/test_hatenadiary.rb"]

  s.add_dependency "mechanize"
  s.add_dependency "nokogiri"

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
