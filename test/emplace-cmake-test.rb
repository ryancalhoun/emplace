require 'test/unit'
require 'fileutils'
require 'stringio'

require 'emplace/cmake'

class EmplaceCMakeTest < Test::Unit::TestCase

  def setup
    FileUtils.mkdir_p 'projdir'
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

  def testIfElse
    s = project(<<-END).find('if', 'UNIX')
      if(UNIX)
        if(APPLE)
          set(os apple)
        elseif(BSD)
          set(os bsd)
        else()
          set(os linux)
        endif()
      else()
        set(os windows)
      endif()
    END

    assert_equal 'set(os windows)', s.get('else').to_s.chomp

    t = s.get.find('if', 'APPLE')
    assert_equal 'set(os apple)', t.get('if').to_s.chomp
    assert_equal 'set(os bsd)', t.get('elseif', 'BSD').to_s.chomp
    assert_equal 'set(os linux)', t.get('else').to_s.chomp
  end

  def testForeach
    s = project(<<-END).find('foreach', 'file', '${list_of_files}')
      foreach(file ${list_of_files})
        get_filename_component(path ${file} PATH)
      endforeach()
    END

    assert_equal 'get_filename_component(path ${file} PATH)', s.get.to_s.chomp
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

  def testLoadTemplates
    cmake = project(<<-END)
      project(%project%)
      add_executable(%library%_test)
    END

    cmake.apply_template!(
      project: 'foo',
      library: 'bar'
    )

    assert_equal [
      "project(foo)",
      "add_executable(bar_test)"
    ], cmake.to_s.lines.map(&:strip)
  end

  def testMergeProjects
    cmake = project(<<-END)
      project(nope)
      include_directories(foo)
      target_link_libraries(thing wow)
    END
    cmake2 = project(<<-END)
      project(yep)
      include_directories(bar)
      target_link_libraries(thing cool)
      if(UNIX)
        list(APPEND SOURCES
          unix/Foo.cpp
        )
      else()
        list(APPEND SOURCES
          win32/Foo.cpp
        )
      end
    END

    cmake.merge! cmake2
    assert_equal [
      "project(yep)",
      "include_directories(", "foo", "bar", ")",
      "target_link_libraries(", "thing", "wow", "cool", ")"
    ], cmake.to_s.lines.map(&:strip)
  end

  def project(contents)
    Emplace::CMake.new.tap {|proj|
      proj.parse_cmake_file! StringIO.new(contents)
    }
  end
end

