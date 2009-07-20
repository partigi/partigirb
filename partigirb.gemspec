# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{partigirb}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alvaro Bautista", "Fernando Blat"]
  s.date = %q{2009-07-20}
  s.email = ["alvarobp@gmail.com", "ferblape@gmail.com"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/partigirb.rb",
     "lib/partigirb/client.rb",
     "lib/partigirb/core_ext.rb",
     "lib/partigirb/transport.rb",
     "partigirb.gemspec",
     "test/client_test.rb",
     "test/mocks/net_http_mock.rb",
     "test/mocks/response_mock.rb",
     "test/mocks/transport_mock.rb",
     "test/test_helper.rb",
     "test/transport_test.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/alvarobp/partigirb}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{TODO}
  s.test_files = [
    "test/client_test.rb",
     "test/mocks/net_http_mock.rb",
     "test/mocks/response_mock.rb",
     "test/mocks/transport_mock.rb",
     "test/test_helper.rb",
     "test/transport_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
