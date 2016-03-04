require 'test/unit'

require 'emplace'
require 'fileutils'

ENV['CC'] = 'cc'
ENV['CONFIGURATION'] = 'CFG'

class TestEmplace < Test::Unit::TestCase

  def testSystemName
    assert_equal 'linux-x86_64-cc', Travis.new.system_name
    assert_equal 'win-x64-msvc-cfg', AppVeyor.new.system_name
  end

  def testPackageName
    assert_equal 'foo-linux-x86_64-cc.tgz', Travis.new.package_name('foo')
    assert_equal 'foo-win-x64-msvc-cfg.zip', AppVeyor.new.package_name('foo')
  end

  def testCmakeGenerator
    assert_equal 'Unix Makefiles', Travis.new.cmake_generator
    assert_equal 'Visual Studio 14 Win64', AppVeyor.new.cmake_generator
  end

  def testProjectTravis
    travis = Travis.new
    project = Emplace::Project.new 'foo', travis
    project.cmake!
    project.build!
    project.test!
    project.package!
    project.extract!
    assert_equal [
      'cmake . -Bbuild -DCMAKE_INSTALL_PREFIX=dist/foo -G "Unix Makefiles"',
      'cmake --build build --target install',
      'ctest --verbose',
      'tar czf foo-linux-x86_64-cc.tgz foo',
      'tar xzf foo-linux-x86_64-cc.tgz'
    ], travis.commands
  end

  def testProjectAppVeyor
    appveyor = AppVeyor.new
    project = Emplace::Project.new 'foo', appveyor
    project.cmake!
    project.build!
    project.test!
    project.package!
    project.extract!
    assert_equal [
      'cmake . -Bbuild -DCMAKE_INSTALL_PREFIX=dist/foo -G "Visual Studio 14 Win64"',
      'cmake --build build --target install --config CFG',
      'ctest --verbose',
      '7z a foo-win-x64-msvc-cfg.zip foo',
      '7z x foo-win-x64-msvc-cfg.zip'
    ], appveyor.commands
  end

  def testFetchTravis
    FileUtils.mkdir_p 'url_source_dir'
    FileUtils.mkdir_p 'vendor_test_dir'

    File.write('url_source_dir/foo-linux-x86_64-cc.tgz', 'foo')

    travis = Travis.new
    project = Emplace::Project.new 'foo', travis
    project.fetch! "file://#{FileUtils.pwd}/url_source_dir"

    assert_equal 'foo', File.read('vendor/foo-linux-x86_64-cc.tgz')
  ensure
    FileUtils.rm_rf 'url_source_dir'
    FileUtils.rm_rf 'vendor'
  end

  def testFetchAppVeyor
    FileUtils.mkdir_p 'url_source_dir'
    FileUtils.mkdir_p 'vendor'

    File.write('url_source_dir/foo-win-x64-msvc-cfg.zip', 'foo')

    appveyor = AppVeyor.new
    project = Emplace::Project.new 'foo', appveyor
    project.fetch! "file://#{FileUtils.pwd}/url_source_dir"

    assert_equal 'foo', File.read('vendor/foo-win-x64-msvc-cfg.zip')
  ensure
    FileUtils.rm_rf 'url_source_dir'
    FileUtils.rm_rf 'vendor'
  end

  class Travis < Emplace.send(:travis, Emplace::Linux)
    attr_reader :commands
    def arch
      'x86_64'
    end
    def sh(cmd, dir='')
      (@commands ||= []) << cmd
    end
  end

  class AppVeyor < Emplace.send(:appveyor, Emplace::Windows)
    attr_reader :commands
    def arch
      'x64'
    end
    def sh(cmd, dir='')
      (@commands ||= []) << cmd
    end
  end

end
