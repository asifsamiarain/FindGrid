find_path(Grid_INCLUDE_DIR
  NAMES Grid/Grid.h
)
find_library(Grid_LIBRARY
  NAMES Grid
)
find_program(Grid_CONFIG 
  NAMES grid-config
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Grid
  FOUND_VAR Grid_FOUND
  REQUIRED_VARS
    Grid_LIBRARY
    Grid_INCLUDE_DIR
    Grid_CONFIG
  VERSION_VAR Grid_VERSION
)

if(Grid_FOUND)
  set(Grid_LIBRARIES ${Grid_LIBRARY})
  set(Grid_INCLUDE_DIRS ${Grid_INCLUDE_DIR})
endif()

# get Grid flags from grid-config
if(Grid_FOUND)
  execute_process(
    COMMAND ${Grid_CONFIG} --cxx OUTPUT_VARIABLE Grid_CXX
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  separate_arguments(Grid_CXX UNIX_COMMAND "${Grid_CXX}")
  execute_process(
    COMMAND ${Grid_CONFIG} --cxxflags OUTPUT_VARIABLE Grid_CXXFLAGS 
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  separate_arguments(Grid_CXXFLAGS UNIX_COMMAND "${Grid_CXXFLAGS}")
  execute_process(
    COMMAND ${Grid_CONFIG} --ldflags OUTPUT_VARIABLE Grid_LDFLAGS 
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  separate_arguments(Grid_LDFLAGS UNIX_COMMAND "${Grid_LDFLAGS}")
  execute_process(
    COMMAND ${Grid_CONFIG} --libs OUTPUT_VARIABLE Grid_LIBS
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  separate_arguments(Grid_LIBS UNIX_COMMAND "${Grid_LIBS}")
endif()

# sanitize flags
if(Grid_FOUND)
  if ("nvcc" IN_LIST Grid_CXX)
    message(STATUS "Grid uses CUDA")
    set(Grid_CUDA On)
    enable_language(CUDA)
    set(CMAKE_CUDA_COMPILER nvcc)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -x cu")
  endif()
  if (Grid_CUDA)
    list(REMOVE_ITEM Grid_LDFLAGS "-Xcompiler")
    list(REMOVE_ITEM Grid_LDFLAGS "-cudart")
    list(REMOVE_ITEM Grid_LDFLAGS "shared")
    list(APPEND Grid_LIBS CUDA::cudart)
    list(FIND Grid_CXXFLAGS "-ccbin" Grid_ccbin_index)
    if (Grid_ccbin_index GREATER -1)
      math(EXPR Grid_ccbin_index_p1 "${Grid_ccbin_index} + 1")
      list(GET Grid_CXXFLAGS ${Grid_ccbin_index_p1} Grid_HOST_COMPILER)
      list(REMOVE_AT Grid_CXXFLAGS ${Grid_ccbin_index} ${Grid_ccbin_index_p1})
    endif()
    find_package(CUDAToolkit REQUIRED)
  endif()
  list(FILTER Grid_CXXFLAGS EXCLUDE REGEX "-O[0-9]")
  list(REMOVE_ITEM Grid_LIBS "-lGrid")
endif()

# define Grid target
if(Grid_FOUND AND NOT TARGET Grid::Grid)
  add_library(Grid::Grid STATIC IMPORTED)
  set_target_properties(Grid::Grid PROPERTIES
    IMPORTED_LOCATION "${Grid_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${Grid_INCLUDE_DIR}"
    INTERFACE_COMPILE_OPTIONS "${Grid_CXXFLAGS}"
    INTERFACE_LINK_LIBRARIES "${Grid_LIBS}"
    INTERFACE_LINK_OPTIONS "${Grid_LDFLAGS}"
  )
  if (Grid_CUDA)
    set_target_properties(Grid::Grid PROPERTIES
      CUDA_RUNTIME_LIBRARY Shared
  )
  endif()
endif()

mark_as_advanced(
  Grid_INCLUDE_DIR
  Grid_LIBRARY
  Grid_CONFIG
  Grid_CXXFLAGS
  Grid_LDFLAGS
  Grid_LIBS
  Grid_ccbin_index
  Grid_ccbin_index_p1
)
