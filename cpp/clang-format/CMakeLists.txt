project(RunClangFormat CXX)
cmake_minimum_required(VERSION 3.9.0 FATAL_ERROR)

set(root_dir "" CACHE DIRECTORY "Source directory")
set(exclude "" CACHE DIRECTORY "Ignore this directory")


message(INFO root_dir="${root_dir}")
message(INFO exclude="${exclude}")
file(GLOB_RECURSE all_files "${root_dir}/*.cpp" "${root_dir}/*.hpp" "${root_dir}/*.h" "${root_dir}/.c")

list(FILTER all_files EXCLUDE REGEX ^${exclude}/*)
foreach (file ${all_files})
    message(INFO ${file})
endforeach()


add_executable(clang-format-8 IMPORTED)
set_target_properties(clang-format-8 PROPERTIES IMPORTED_LOCATION /usr/bin/clang-format-8)

add_custom_target(
    format-all
    COMMAND clang-format-8
    -style=file
    -fallback-style=LLVM
    -i
    ${all_files}
)
