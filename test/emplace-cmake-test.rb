require 'test/unit'
require 'fileutils'

require 'emplace/cmake'

class EmplaceCMakeTest < Test::Unit::TestCase

  def setup
    FileUtils.mkdir 'projdir'
  end

  def teardown
    FileUtils.rm_rf 'projdir'
  end

  def testHasCmakeLists
    assert_false Emplace::CMake.new('projdir').has_cmake_lists?
    File.open('projdir/CMakeLists.txt', 'w') {}
    assert_true Emplace::CMake.new('projdir').has_cmake_lists?
  end

  def testProjectName
    File.open('projdir/CMakeLists.txt', 'w') {|f|
      f.puts 'project(foo)'
    }
    assert_equal 'foo', Emplace::CMake.new('projdir').project_name
  end

  def testLibraryName
    File.open('projdir/CMakeLists.txt', 'w') {|f|
      f.puts 'add_library('
      f.puts '   foo'
      f.puts '   STATIC'
      f.puts '   ${SOURCES}'
      f.puts ')'
    }
    assert_equal 'foo', Emplace::CMake.new('projdir').library_name
  end
  def testExecutableName
    File.open('projdir/CMakeLists.txt', 'w') {|f|
      f.puts 'add_executable('
      f.puts '   foo'
      f.puts '   ${SOURCES}'
      f.puts ')'
    }
    assert_equal 'foo', Emplace::CMake.new('projdir').executable_name
  end
  def testIsRoot
    File.open('projdir/CMakeLists.txt', 'w') {|f|
      f.puts 'add_executable('
      f.puts '   foo'
      f.puts '   ${SOURCES}'
      f.puts ')'
    }
    assert_false Emplace::CMake.new('projdir').is_root?

    File.open('projdir/CMakeLists.txt', 'w') {|f|
      f.puts 'project('
      f.puts '   foo'
      f.puts ')'
    }
    assert_true Emplace::CMake.new('projdir').is_root?
  end
end

