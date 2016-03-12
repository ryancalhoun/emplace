#  Unix global definitions

set(warning_flags "-Werror=return-type -Wno-unused-local-typedefs")
if(APPLE)
	set(warning_flags "${warning_flags} -Wno-overloaded-virtual")
endif()

set(CMAKE_CXX_FLAGS "-Wall -fPIC -fno-omit-frame-pointer -fno-strict-aliasing -g -O2 ${warning_flags}")
set(CMAKE_C_FLAGS "-Wall -fPIC -fno-omit-frame-pointer -fno-strict-aliasing -g -O2 ${warning_flags}")

macro(_install_static_lib_symbols proj dir)
	# nothing to do
endmacro()
