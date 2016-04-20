cmake_minimum_required(VERSION 2.8)

project(%project%)

include(Emplace)

enable_testing()

include_directories(
	${CMAKE_SOURCE_DIR}/src/lib
)

file(GLOB_RECURSE subprojects ./*/CMakeLists.txt)
foreach(cmake_file in ${subprojects})
	get_filename_component(cmake_dir ${cmake_file} PATH)
	add_subdirectory(${cmake_dir})
endforeach()

install(
	DIRECTORY include/
	DESTINATION include
	FILES MATCHING PATTERN "*.h" PATTERN "*.hpp"
)
