require 'test/unit'

require 'emplace'

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
    assert_equal [
      'cmake . -Bbuild -DCMAKE_INSTALL_PREFIX=dist/foo -G "Unix Makefiles"',
      'cmake --build build --target install',
      'ctest --verbose',
      'tar czf foo-linux-x86_64-cc.tgz foo'
    ], travis.commands
  end

  def testProjectAppVeyor
    appveyor = AppVeyor.new
    project = Emplace::Project.new 'foo', appveyor
    project.cmake!
    project.build!
    project.test!
    project.package!
    assert_equal [
      'cmake . -Bbuild -DCMAKE_INSTALL_PREFIX=dist/foo -G "Visual Studio 14 Win64"',
      'cmake --build build --target install --config CFG',
      'ctest --verbose',
      '7z a foo-win-x64-msvc-cfg.zip foo'
    ], appveyor.commands
  end

  class Travis < Emplace::Linux
    attr_reader :commands
    include Emplace::Travis
    def arch
      'x86_64'
    end
    def sh(cmd, dir='')
      (@commands ||= []) << cmd
    end
  end

  class AppVeyor < Emplace::Windows
    attr_reader :commands
    include Emplace::AppVeyor
    def arch
      'x64'
    end
    def sh(cmd, dir='')
      (@commands ||= []) << cmd
    end
  end

end
