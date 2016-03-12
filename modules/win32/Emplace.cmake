# Windows MSVC global definitions

string(REGEX REPLACE "/STACK:[0-9]+" "" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "/DWIN32 /D_WINDOWS /W3 /Zm1000 /EHsc /GR")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1")
set(CMAKE_C_FLAGS_DEBUG_INIT "/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1")

macro(_install_static_lib_symbols proj dir)
	install(
		FILES "${CMAKE_CURRENT_BINARY_DIR}/$(IntDir)${proj}.pdb"
		DESTINATION symbols
		OPTIONAL
	)
endmacro()
