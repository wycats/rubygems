require File.join(File.expand_path(File.dirname(__FILE__)), 'gemutilities')
require 'rubygems/runtime_source_index'
require 'rubygems/config_file'
require 'pathname'

class TestGemSourceIndex < RubyGemTestCase

  def setup
    super
    
    util_make_gems
    
    dir = File.dirname(__FILE__)
    index = Pathname.new(dir).join("runtime_index_fixture")
    FileUtils.rm_rf(index)
    FileUtils.mkdir_p(index)
    FileUtils.mkdir_p(index.join("specifications"))

    [@a1, @a2, @a3a, @a_evil9, @c1_2].each do |spec|
      spec_dir = index.join("specifications", spec.name)
      FileUtils.mkdir_p(spec_dir)
      File.open(spec_dir.join("#{spec.version}.gemspec"), "w") do |file|
        file.puts spec.to_ruby
      end
    end
    
    @source_index = Gem::RuntimeSourceIndex.from_gems_in(index)
  end
  
  def test_search
    with_version = Gem::Dependency.new('a', '>= 2')
    assert_equal [@a2, @a3a], @source_index.search(with_version)

    with_default = Gem::Dependency.new('a', Gem::Requirement.default)
    assert_equal [@a1, @a2, @a3a], @source_index.search(with_default)

    c1_1_dep = Gem::Dependency.new 'c', '~> 1.1'
    assert_equal [@c1_2], @source_index.search(c1_1_dep)
  end

end