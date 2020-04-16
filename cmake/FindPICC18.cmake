
SET(PICC18_PATH "/opt/hitech/picc-18/pro/9.63PL3/bin/picc18" CACHE STRING "Path to picc-18 compiler")
SET(CMAKE_EXE_LINKER_FLAGS "")

FUNCTION(ADD_HEX _project_name _default_chip)

	SET(CHIP ${_default_chip} CACHE STRING "The chip to build for")
	SET(_hex_file "${_project_name}.hex")

	GET_DIRECTORY_PROPERTY(_include_dirs INCLUDE_DIRECTORIES)

	SET(_include_arg "-I${CMAKE_CURRENT_SOURCE_DIR}")
	FOREACH(_dir ${_include_dirs})
		LIST(APPEND _include_arg "-I${_dir}")
	ENDFOREACH(_dir)

	GET_DIRECTORY_PROPERTY(_definitions DIRECTORY ${CMAKE_SOURCE_DIR} COMPILE_DEFINITIONS)

	FOREACH(_def ${_definitions})
		LIST(APPEND _definitionlist "-D${_def}")
	ENDFOREACH(_def)

	#Loop all sources and setup a custom build-command for each
	FOREACH(_file ${ARGN})
		GET_FILENAME_COMPONENT(_abs_file ${_file} ABSOLUTE)
		GET_FILENAME_COMPONENT(_filename ${_file} NAME_WE)
		GET_FILENAME_COMPONENT(_ext ${_file} EXT)

		GET_PROPERTY(_dir SOURCE ${_file} PROPERTY P1_PATH)
		IF (NOT _dir)
			GET_FILENAME_COMPONENT(_dir ${_file} PATH)
		ENDIF(NOT _dir)

		IF (_dir STREQUAL "")
			SET(_p1_path "${_filename}.p1")
		ELSE (_dir STREQUAL "")
			SET(_p1_path "${_dir}/${_filename}.p1")
			MAKE_DIRECTORY(${CMAKE_BINARY_DIR}/${_dir})
		ENDIF(_dir STREQUAL "")

		IF(_ext STREQUAL ".c")
			ADD_CUSTOM_COMMAND(OUTPUT ${_p1_path}
				COMMAND ${PICC18_PATH} ${_definitionlist} --chip=${CHIP} ${CMAKE_C_FLAGS} --errformat='%f:%l: error[%n]: %s' --outdir=${CMAKE_BINARY_DIR}/${_dir} ${_include_arg} --pass1 "${_abs_file}"
				DEPENDS ${_abs_file}
				IMPLICIT_DEPENDS C ${_abs_file}
				COMMENT "Compiling ${_file}"
			)
			LIST(APPEND _p1_sources ${_p1_path})
		ENDIF()
		LIST(APPEND _sources ${_file})
	ENDFOREACH(_file)

	ADD_CUSTOM_COMMAND(OUTPUT ${_hex_file}
		COMMAND ${PICC18_PATH} --chip=${CHIP} ${CMAKE_EXE_LINKER_FLAGS} ${_p1_sources} --outdir=${CMAKE_BINARY_DIR} -O${_hex_file}
		DEPENDS ${_p1_sources}
		COMMENT "Linking ${_hex_file}"
	)

	ADD_CUSTOM_TARGET(${_project_name} ALL
		SOURCES ${_sources} ${_p1_sources} ${_hex_file}
	)
	SET_TARGET_PROPERTIES(${_project_name} PROPERTIES HEX_FILE ${_hex_file})

	OPTION(FLASH_PICKIT2 FALSE "Flash the hex using PICkit 2 after a successful build")
	IF(FLASH_PICKIT2)
		ADD_CUSTOM_COMMAND(TARGET ${_project_name} POST_BUILD
			COMMAND pk2cmd -PPIC${CHIP} -F${CMAKE_CURRENT_BINARY_DIR}/${_hex_file} -M -R
			DEPENDS ${_hex_file}
			COMMENT "Flashing ${_hex_file}"
		)
	ENDIF(FLASH_PICKIT2)

ENDFUNCTION(ADD_HEX)
