#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'rubygems'

class TestGemPaths < Test::Unit::TestCase
  def setup
    Gem.clear_paths
    ENV['GEM_HOME'] = nil
    ENV['GEM_PATH'] = nil
  end

  def teardown
    setup
  end

  DEFAULT_DIR_RE = %r{/ruby/gems/[0-9.]+}
  TEST_GEMDIR = 'test/temp/gemdir'

  def test_default_dir
    assert_match DEFAULT_DIR_RE, Gem.dir
  end

  def test_default_dir_subdirectories
    Gem::DIRECTORIES.each do |filename|
      assert File.exists?(File.join(Gem.dir, filename)), "expected #{filename} to exist"
    end
  end

  def test_gem_home
    ENV['GEM_HOME'] = TEST_GEMDIR
    assert_equal TEST_GEMDIR, Gem.dir
  end

  def test_gem_home_subdirectories
    ENV['GEM_HOME'] = TEST_GEMDIR
    ['cache', 'doc', 'gems', 'specifications'].each do |filename|
      assert File.exists?(File.join(TEST_GEMDIR, filename)), "expected #{filename} to exist"
    end
  end

  def test_default_path
    assert_equal [Gem.dir], Gem.path
  end

  ADDITIONAL = ['test/temp/a', 'test/temp/b']

  def test_additional_paths
    create_additional_gem_dirs
    ENV['GEM_PATH'] = ADDITIONAL.join(File::PATH_SEPARATOR)
    assert_equal ADDITIONAL, Gem.path[0,2]
    assert_equal 3, Gem.path.size
    assert_match DEFAULT_DIR_RE, Gem.path.last
  end

  def test_dir_path_overlap
    create_additional_gem_dirs
    ENV['GEM_HOME'] = 'test/temp/gemdir'
    ENV['GEM_PATH'] = ADDITIONAL.join(File::PATH_SEPARATOR)
    assert_equal 'test/temp/gemdir', Gem.dir
    assert_equal ADDITIONAL + [Gem.dir], Gem.path
  end

  def test_dir_path_overlaping_duplicates_removed
    create_additional_gem_dirs
    dirs = ['test/temp/gemdir'] + ADDITIONAL + ['test/temp/a']
    ENV['GEM_HOME'] = 'test/temp/gemdir'
    ENV['GEM_PATH'] = dirs.join(File::PATH_SEPARATOR)
    assert_equal 'test/temp/gemdir', Gem.dir
    assert_equal [Gem.dir] + ADDITIONAL, Gem.path
  end

  def test_path_use_home
    create_additional_gem_dirs
    Gem.use_paths("test/temp/gemdir")
    assert_equal "test/temp/gemdir", Gem.dir
    assert_equal [Gem.dir], Gem.path
  end

  def test_path_use_home_and_dirs
    create_additional_gem_dirs
    Gem.use_paths("test/temp/gemdir", ADDITIONAL)
    assert_equal "test/temp/gemdir", Gem.dir
    assert_equal ADDITIONAL+[Gem.dir], Gem.path
  end

  def test_user_home
    if ENV['HOME']
      assert_equal ENV['HOME'], Gem.user_home
    end
  end

  def test_ensure_gem_directories_new
    FileUtils.rm_r("test/temp/gemdir")
    Gem.use_paths("test/temp/gemdir")
    Gem.send(:ensure_gem_subdirectories, "test/temp/gemdir")
    assert File.exist?("test/temp/gemdir/cache")
  end

  def test_ensure_gem_directories_missing_parents
    gemdir = "test/temp/a/b/c/gemdir"
    FileUtils.rm_r("test/temp/a") rescue nil
    Gem.use_paths(gemdir)
    Gem.send(:ensure_gem_subdirectories, gemdir)
    assert File.exist?("#{gemdir}/cache")
  end

  def test_ensure_gem_directories_write_protected
    gemdir = "test/temp/egd"
    FileUtils.rm_r gemdir rescue nil
    FileUtils.mkdir_p gemdir
    FileUtils.chmod 0400, gemdir
    Gem.use_paths(gemdir)
    Gem.send(:ensure_gem_subdirectories, gemdir)
    assert ! File.exist?("#{gemdir}/cache")
  ensure
    FileUtils.chmod(0600, gemdir) rescue nil
    FileUtils.rm_r gemdir rescue nil
  end

  def test_ensure_gem_directories_with_parents_write_protected
    parent = "test/temp/egd"
    gemdir = "#{parent}/a/b/c"
    
    FileUtils.rm_r parent rescue nil
    FileUtils.mkdir_p parent
    FileUtils.chmod 0400, parent
    Gem.use_paths(gemdir)
    Gem.send(:ensure_gem_subdirectories, gemdir)
    assert ! File.exist?("#{gemdir}/cache")
  ensure
    FileUtils.chmod(0600, parent) rescue nil
    FileUtils.rm_r parent rescue nil
  end

  private

  def create_additional_gem_dirs
    create_gem_dir('test/temp/gemdir')
    ADDITIONAL.each do |dir| create_gem_dir(dir) end
  end

  def create_gem_dir(fn)
    Gem::DIRECTORIES.each do |subdir|
      FileUtils.mkdir_p(File.join(fn, subdir))
    end
  end

  def redirect_stderr(io)
    old_err = $stderr
    $stderr = io
    yield
  ensure
    $stderr = old_err
  end
end

