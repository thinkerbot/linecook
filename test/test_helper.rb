require 'rubygems'
require 'bundler'
runtime = Bundler.setup

# Workaround the performance penalty of reactivating bundler on each system
# call to linecook - see https://github.com/carlhuda/bundler/issues/1323
rubyopt = []
runtime.gems.each do |gemspec|
  gemspec.require_paths.each do |require_path|
    rubyopt.unshift "-I#{File.join(gemspec.full_gem_path, require_path)}"
  end
end
ENV['RUBYOPT']=rubyopt.join(' ')

require 'shell_test/unit'

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end

# Use these instead of setting PATH to bin dir to avoid potential
# warnings about a world writable directory being on PATH
LINECOOK_PATH = File.expand_path('../../bin/linecook', __FILE__)
LINECOOK_EXE  = "ruby '#{LINECOOK_PATH}'"

# Updates ShellTest::FileMethods in the same way as Linecook::Test such that
# multitesting is possible.  Include after ShellTest::FileMethods.
module FileMethodsShim
  def method_dir
    @host_method_dir ||= begin
      if test_host = ENV['LINECOOK_TEST_HOST']
        File.join(super, test_host)
      else
        super
      end
    end
  end
end

# Helpers for testing linecook with various gem fixtures installed.
module GemTestHelpers
  FIXTURES_DIR = File.expand_path('../fixtures', __FILE__)

  def gem_fixture_dir
    path('fixtures')
  end

  def gem_install_dir
    path('gems')
  end

  def gem_path(name, version, *relative_path)
    File.join(gem_fixture_dir, "#{name}-#{version}", *relative_path)
  end

  def build_gem_fixture(name, version)
    gemspec = prepare gem_path(name, version, "#{name}.gemspec") do |io|
      io << Gem::Specification.new do |s|
        s.name    = name
        s.version = version
        s.summary = "Summary #{name} #{version}"
        s.require_paths = ["lib"]
        yield(s)
      end.to_ruby
    end

    Dir.chdir gem_path(name, version) do
      cmd = "gem build '#{gemspec}' 2>&1"
      stdout = `#{cmd}`

      unless $?.exitstatus == 0
        raise "failure to build gem:\n#{cmd}\n#{stdout}"
      end

      FileUtils.mv gem_path(name, version, "#{name}-#{version}.gem"), gem_fixture_dir
    end
  end

  def prepare_gem_file(spec, path, content=nil, &block)
    prepare(gem_path(spec.name, spec.version, path), content, &block)
    spec.files << path
  end

  def install_gem_fixtures
    gemfiles = Dir.glob File.join(gem_fixture_dir, '*.gem')
    gemfiles.each do |gemfile|
      cmd = "gem install '#{gemfile}' --local --no-rdoc --no-ri --install-dir '#{gem_install_dir}' 2>&1"
      stdout = `#{cmd}`

      unless $?.exitstatus == 0
        raise "failure to install gem:\n#{cmd}\n#{stdout}"
      end
    end
  end

  def with_gem_env
    # Bundler.with_clean_env do
      current_gem_home = ENV['GEM_HOME']
      current_gem_path = ENV['GEM_PATH']
      begin
        ENV['GEM_HOME'] = gem_install_dir
        ENV['GEM_PATH'] = gem_install_dir
        yield
      rescue
        ENV['GEM_HOME'] = current_gem_home
        ENV['GEM_PATH'] = current_gem_path
      end
    # end
  end

  def with_gem_fixtures(&block)
    install_gem_fixtures
    with_gem_env(&block)
  end
end