find_path(Hadrons_INCLUDE_DIR
  NAMES Hadrons/Global.hpp
)
find_library(Hadrons_LIBRARY
  NAMES Hadrons
)
find_program(Hadrons_CONFIG 
  NAMES hadrons-config
)

find_package(Grid REQUIRED)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Hadrons
  FOUND_VAR Hadrons_FOUND
  REQUIRED_VARS
    Hadrons_LIBRARY
    Hadrons_INCLUDE_DIR
    Hadrons_CONFIG
  VERSION_VAR Hadrons_VERSION
)

if(Hadrons_FOUND)
  set(Hadrons_LIBRARIES ${Hadrons_LIBRARY})
  set(Hadrons_INCLUDE_DIRS ${Hadrons_INCLUDE_DIR})
endif()

# get Hadrons flags from grid-config
if(Hadrons_FOUND)
  execute_process(
      COMMAND ${Hadrons_CONFIG} --cxx OUTPUT_VARIABLE Hadrons_CXX
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  separate_arguments(Hadrons_CXX UNIX_COMMAND "${Hadrons_CXX}")
  if ("nvcc" IN_LIST Hadrons_CXX)
    message(STATUS "Hadrons uses CUDA")
    set(Hadrons_CUDA On)
    enable_language(CUDA)
    set(CMAKE_CUDA_COMPILER nvcc)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -x cu")
  endif()
  execute_process(
    COMMAND ${Hadrons_CONFIG} --cxxflags OUTPUT_VARIABLE Hadrons_CXXFLAGS 
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  separate_arguments(Hadrons_CXXFLAGS UNIX_COMMAND "${Hadrons_CXXFLAGS}")
  execute_process(
    COMMAND ${Hadrons_CONFIG} --ldflags OUTPUT_VARIABLE Hadrons_LDFLAGS 
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  separate_arguments(Hadrons_LDFLAGS UNIX_COMMAND "${Hadrons_LDFLAGS}")
  execute_process(
    COMMAND ${Hadrons_CONFIG} --libs OUTPUT_VARIABLE Hadrons_LIBS
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  separate_arguments(Hadrons_LIBS UNIX_COMMAND "${Hadrons_LIBS}")
endif()

# sanitize flags
if(Hadrons_FOUND)
  if (Hadrons_CUDA)
    list(REMOVE_ITEM Hadrons_LDFLAGS "-Xcompiler")
    list(REMOVE_ITEM Hadrons_LDFLAGS "-cudart")
    list(REMOVE_ITEM Hadrons_LDFLAGS "shared")
    list(FIND Hadrons_CXXFLAGS "-ccbin" Hadrons_ccbin_index)
    if (Hadrons_ccbin_index GREATER -1)
      math(EXPR Hadrons_ccbin_index_p1 "${Hadrons_ccbin_index} + 1")
      list(GET Hadrons_CXXFLAGS ${Hadrons_ccbin_index_p1} Hadrons_HOST_COMPILER)
      list(REMOVE_AT Hadrons_CXXFLAGS ${Hadrons_ccbin_index} ${Hadrons_ccbin_index_p1})
    endif()
  endif()
  list(FILTER Hadrons_CXXFLAGS EXCLUDE REGEX "-O[0-9]")
  list(REMOVE_ITEM Hadrons_LIBS "-lGrid")
endif()

# define Hadrons target
if(Hadrons_FOUND AND NOT TARGET Hadrons::Hadrons)
  add_library(Hadrons::Hadrons STATIC IMPORTED)
  set_target_properties(Hadrons::Hadrons PROPERTIES
    IMPORTED_LOCATION "${Hadrons_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${Hadrons_INCLUDE_DIR}"
    INTERFACE_COMPILE_OPTIONS "${Hadrons_CXXFLAGS}"
    INTERFACE_LINK_LIBRARIES "${Hadrons_LIBS};Grid::Grid"
    INTERFACE_LINK_OPTIONS "${Hadrons_LDFLAGS}"
  )
endif()

mark_as_advanced(
  Hadrons_INCLUDE_DIR
  Hadrons_LIBRARY
  Hadrons_CONFIG
  Hadrons_CXXFLAGS
  Hadrons_LDFLAGS
  Hadrons_LIBS
  Hadrons_ccbin_index
  Hadrons_ccbin_index_p1
)
