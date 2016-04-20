install_symbols(TARGETS %library% %type% DESTINATION lib)
install(TARGETS %library% DESTINATION lib)
install(FILES ${HEADERS} DESTINATION include/%library%)
