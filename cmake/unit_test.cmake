project(%library%_test)

set(SOURCES
)

include_directories(
	${CMAKE_SOURCE_DIR}/src/lib/%library%
)

add_executable(%library%_test ${SOURCES})
add_test(%library%_test %library%_test -v)

target_link_libraries(
	%library%_test
	%library%

	cppunit
)

