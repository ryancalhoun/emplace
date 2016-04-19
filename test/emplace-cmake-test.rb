require 'test/unit'
require 'fileutils'
require 'stringio'

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
    assert_equal 'foo', project(<<-END).project_name
      project(foo)
    END
  end

  def testLibraryName
    assert_equal 'foo', project(<<-END).library_name
      add_library(
         foo
         STATIC
         ${SOURCES}
      )'
    END
  end
  def testExecutableName
    assert_equal 'foo', project(<<-END).executable_name
      add_executable(
         foo
         ${SOURCES}
      )
    END
  end
  def testIsRoot
    assert_false project(<<-END).is_root?
      add_executable(
         foo
         ${SOURCES}
      )
    END
    assert_true project(<<-END).is_root?
      project(
         foo
      )
    END
  end

  def testFindRoot
    FileUtils.mkdir_p 'projdir/src/lib/foo'
    File.open('projdir/src/lib/foo/CMakeLists.txt', 'w') {|f|
      f.write <<-END
      add_library(foo ${SOURCES}
      END
    }
    assert_raises {
       Emplace::CMake.new('projdir/src/lib/foo').find_root.path
    }

    File.open('projdir/CMakeLists.txt', 'w') {|f|
      f.write <<-END
      project(root_project)
      END
    }
    assert_equal File.absolute_path('projdir'), Emplace::CMake.new('projdir').find_root.path
    assert_equal File.absolute_path('projdir'), Emplace::CMake.new('projdir/src/lib/foo').find_root.path
  end

  def testStatements
    assert_equal %w(project include_directories link_libraries), project(<<-END).statements.map(&:name)
      project(foo)

      include_directories (
        /usr/include
        ${CMAKE_CURRENT_SOURCE_DIR}
      )

      link_libraries(
        bar thing
      )
    END
  end

  def testArguments
    assert_equal %w(one "" "two"), project(<<-END).find('link_libraries').arguments
      link_libraries (
        one

        ""

        "two"
      )
    END
  end

  def toS
    text = <<-END
      # CMAKE PROJECT

      project(foo)

      include_directories (
        /usr/include
        ${CMAKE_CURRENT_SOURCE_DIR}
      )

      link_libraries(
        bar thing
      )

    END

    assert_equal text, project(text).to_s
  end

  def testSave
    cmake = Emplace::CMake.new 'projdir/foo', name: 'foo'
    cmake.save!

    assert_true File.exists?('projdir/foo/CMakeLists.txt')
    assert_equal "project(foo)\n", cmake.to_s
  end

  def testAddSourceFiles
    cmake = Emplace::CMake.new 'projdir/foo'
    cmake.library('foo').sources << 'Foo.cpp' << 'Foo.h'

    assert_equal "add_library(foo Foo.cpp Foo.h)\n", cmake.to_s
  end

  def project(contents)
    Emplace::CMake.new.tap {|proj|
      proj.parse_cmake_file! StringIO.new(contents)
    }
  end
end

