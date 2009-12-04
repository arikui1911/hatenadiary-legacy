Gem::Specification.new do |s|
  s.name = %q{hatenadiary}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["arikui"]
  s.date = %q{2009-12-04}
  s.description = %q{A client for Hatena Diary to post and delete blog entries.}
  s.email = %q{arikui.ruby@gmail.com}
  s.extra_rdoc_files = ["README", "LICENSE", "ChangeLog"]
  s.files = ["lib/hatenadiary.rb", "test/test_hatenadiary.rb", "README", "LICENSE", "ChangeLog"]
  s.homepage = %q{http://wiki.github.com/arikui1911/hatenadiary}
  s.rdoc_options = ["--title", "hatenadiary documentation", "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{hatenadiary}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{It is a library provides a client for Hatena Diary to post and delete blog entries.}
  s.test_files = ["test/test_hatenadiary.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mechanize>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, ["= 1.3.3"])
    else
      s.add_dependency(%q<mechanize>, [">= 0"])
      s.add_dependency(%q<nokogiri>, ["= 1.3.3"])
    end
  else
    s.add_dependency(%q<mechanize>, [">= 0"])
    s.add_dependency(%q<nokogiri>, ["= 1.3.3"])
  end
end
