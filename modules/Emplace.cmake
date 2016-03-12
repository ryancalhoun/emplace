include(CMakeParseArguments)

if(UNIX)
	include(unix/Emplace)
elseif(WIN32)
	include(win32/Emplace)
endif()

macro(install_symbols)
	cmake_parse_arguments(install_args "STATIC" "DESTINATION" "TARGETS" ${ARGN})

	foreach(target ${install_args_TARGETS})
		if(${install_args_STATIC} STREQUAL "TRUE")
			_install_static_lib_symbols(${target} ${install_args_DESTINATION})
		endif()
	endforeach()
endmacro()
