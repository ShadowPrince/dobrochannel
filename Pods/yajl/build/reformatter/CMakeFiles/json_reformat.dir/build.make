# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.4

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.4.0/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.4.0/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build

# Include any dependencies generated for this target.
include reformatter/CMakeFiles/json_reformat.dir/depend.make

# Include the progress variables for this target.
include reformatter/CMakeFiles/json_reformat.dir/progress.make

# Include the compile flags for this target's objects.
include reformatter/CMakeFiles/json_reformat.dir/flags.make

reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o: reformatter/CMakeFiles/json_reformat.dir/flags.make
reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o: ../reformatter/json_reformat.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o"
	cd /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/json_reformat.dir/json_reformat.c.o   -c /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/reformatter/json_reformat.c

reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/json_reformat.dir/json_reformat.c.i"
	cd /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/reformatter/json_reformat.c > CMakeFiles/json_reformat.dir/json_reformat.c.i

reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/json_reformat.dir/json_reformat.c.s"
	cd /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/reformatter/json_reformat.c -o CMakeFiles/json_reformat.dir/json_reformat.c.s

reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o.requires:

.PHONY : reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o.requires

reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o.provides: reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o.requires
	$(MAKE) -f reformatter/CMakeFiles/json_reformat.dir/build.make reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o.provides.build
.PHONY : reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o.provides

reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o.provides.build: reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o


# Object files for target json_reformat
json_reformat_OBJECTS = \
"CMakeFiles/json_reformat.dir/json_reformat.c.o"

# External object files for target json_reformat
json_reformat_EXTERNAL_OBJECTS =

reformatter/json_reformat: reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o
reformatter/json_reformat: reformatter/CMakeFiles/json_reformat.dir/build.make
reformatter/json_reformat: yajl-1.0.12/lib/libyajl_s.a
reformatter/json_reformat: reformatter/CMakeFiles/json_reformat.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking C executable json_reformat"
	cd /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/json_reformat.dir/link.txt --verbose=$(VERBOSE)
	cd /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter && /usr/local/Cellar/cmake/3.4.0/bin/cmake -E copy_if_different /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter/json_reformat /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter/../yajl-1.0.12/bin

# Rule to build all files generated by this target.
reformatter/CMakeFiles/json_reformat.dir/build: reformatter/json_reformat

.PHONY : reformatter/CMakeFiles/json_reformat.dir/build

reformatter/CMakeFiles/json_reformat.dir/requires: reformatter/CMakeFiles/json_reformat.dir/json_reformat.c.o.requires

.PHONY : reformatter/CMakeFiles/json_reformat.dir/requires

reformatter/CMakeFiles/json_reformat.dir/clean:
	cd /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter && $(CMAKE_COMMAND) -P CMakeFiles/json_reformat.dir/cmake_clean.cmake
.PHONY : reformatter/CMakeFiles/json_reformat.dir/clean

reformatter/CMakeFiles/json_reformat.dir/depend:
	cd /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/reformatter /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter /Users/sp/Library/Caches/CocoaPods/Pods/Release/yajl/1.0.12-e435f/build/reformatter/CMakeFiles/json_reformat.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : reformatter/CMakeFiles/json_reformat.dir/depend

