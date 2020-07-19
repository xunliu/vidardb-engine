# Copyright (c) 2011 The LevelDB Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.

# Inherit some settings from environment variables, if available

#-----------------------------------------------

CLEAN_FILES = # deliberately empty, so we can append below.
CFLAGS += ${EXTRA_CFLAGS}
CXXFLAGS += ${EXTRA_CXXFLAGS}
LDFLAGS += $(EXTRA_LDFLAGS)
MACHINE ?= $(shell uname -m)
ARFLAGS = rs

# Users can specify their own configuration
REGISTRY ?= vidardb
IMAGE ?= vidardb
TAG ?= latest
DOCKER ?= docker
NETWORK ?= default
APT_OPTS ?=
ENV_EXTS ?=
CMAKE_FLAGS ?=

# Transform parallel LOG output into something more readable.
perl_command = perl -n \
  -e '@a=split("\t",$$_,-1); $$t=$$a[8];'				\
  -e '$$t =~ /.*if\s\[\[\s"(.*?\.[\w\/]+)/ and $$t=$$1;'		\
  -e '$$t =~ s,^\./,,;'							\
  -e '$$t =~ s, >.*,,; chomp $$t;'					\
  -e '$$t =~ /.*--gtest_filter=(.*?\.[\w\/]+)/ and $$t=$$1;'		\
  -e 'printf "%7.3f %s %s\n", $$a[3], $$a[6] == 0 ? "PASS" : "FAIL", $$t'
quoted_perl_command = $(subst ','\'',$(perl_command))

# DEBUG_LEVEL can have three values:
# * DEBUG_LEVEL=2; this is the ultimate debug mode. It will compile vidardb
# without any optimizations. To compile with level 2, issue `make dbg`
# * DEBUG_LEVEL=1; debug level 1 enables all assertions and debug code, but
# compiles vidardb with -O2 optimizations. this is the default debug level.
# `make all` or `make <binary_target>` compile VidarDB with debug level 1.
# We use this debug level when developing VidarDB.
# * DEBUG_LEVEL=0; this is the debug level we use for release. If you're
# running vidardb in production you most definitely want to compile VidarDB
# with debug level 0. To compile with level 0, run `make shared_lib`,
# `make install-shared`, `make static_lib`, `make install-static` or
# `make install`

# Set the default DEBUG_LEVEL to 2
DEBUG_LEVEL?=2

ifeq ($(MAKECMDGOALS),dbg)
	DEBUG_LEVEL=2
endif

ifeq ($(MAKECMDGOALS),clean)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),release)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),shared_lib)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),install-shared)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),static_lib)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),install-static)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),install)
	DEBUG_LEVEL=0
endif

# compile with -O2 if debug level is not 2
ifneq ($(DEBUG_LEVEL), 2)
OPT += -O2 -fno-omit-frame-pointer
# Skip for archs that don't support -momit-leaf-frame-pointer
ifeq (,$(shell $(CXX) -fsyntax-only -momit-leaf-frame-pointer -xc /dev/null 2>&1))
OPT += -momit-leaf-frame-pointer
endif
endif

# if we're compiling for release, compile without debug code (-DNDEBUG) and
# don't treat warnings as errors
ifeq ($(DEBUG_LEVEL),0)
OPT += -DNDEBUG
DISABLE_WARNING_AS_ERROR=1
else
$(warning Warning: Compiling in debug mode. Don't use the resulting binary in production)
endif

#-----------------------------------------------
include src.mk

AM_DEFAULT_VERBOSITY = 0

AM_V_GEN = $(am__v_GEN_$(V))
am__v_GEN_ = $(am__v_GEN_$(AM_DEFAULT_VERBOSITY))
am__v_GEN_0 = @echo "  GEN     " $@;
am__v_GEN_1 =
AM_V_at = $(am__v_at_$(V))
am__v_at_ = $(am__v_at_$(AM_DEFAULT_VERBOSITY))
am__v_at_0 = @
am__v_at_1 =

AM_V_CC = $(am__v_CC_$(V))
am__v_CC_ = $(am__v_CC_$(AM_DEFAULT_VERBOSITY))
am__v_CC_0 = @echo "  CC      " $@;
am__v_CC_1 =
CCLD = $(CC)
LINK = $(CCLD) $(AM_CFLAGS) $(CFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@
AM_V_CCLD = $(am__v_CCLD_$(V))
am__v_CCLD_ = $(am__v_CCLD_$(AM_DEFAULT_VERBOSITY))
am__v_CCLD_0 = @echo "  CCLD    " $@;
am__v_CCLD_1 =
AM_V_AR = $(am__v_AR_$(V))
am__v_AR_ = $(am__v_AR_$(AM_DEFAULT_VERBOSITY))
am__v_AR_0 = @echo "  AR      " $@;
am__v_AR_1 =

AM_LINK = $(AM_V_CCLD)$(CXX) $^ $(EXEC_LDFLAGS) -o $@ $(LDFLAGS) $(COVERAGEFLAGS)

# detect what platform we're building on
dummy := $(shell (export VIDARDB_ROOT="$(CURDIR)"; "$(CURDIR)/build_tools/build_detect_platform" "$(CURDIR)/make_config.mk"))
# this file is generated by the previous line to set build flags and sources
include make_config.mk
CLEAN_FILES += make_config.mk

ifneq ($(PLATFORM), IOS)
CFLAGS += -g
CXXFLAGS += -g
else
# no debug info for IOS, that will make our library big
OPT += -DNDEBUG
endif

ifeq ($(PLATFORM), OS_SOLARIS)
	PLATFORM_CXXFLAGS += -D _GLIBCXX_USE_C99
endif

# ASAN doesn't work well with jemalloc. If we're compiling with ASAN, we should use regular malloc.
ifdef COMPILE_WITH_ASAN
	DISABLE_JEMALLOC=1
	EXEC_LDFLAGS += -fsanitize=address
	PLATFORM_CCFLAGS += -fsanitize=address
	PLATFORM_CXXFLAGS += -fsanitize=address
endif

# TSAN doesn't work well with jemalloc. If we're compiling with TSAN, we should use regular malloc.
ifdef COMPILE_WITH_TSAN
	DISABLE_JEMALLOC=1
	EXEC_LDFLAGS += -fsanitize=thread -pie
	PLATFORM_CCFLAGS += -fsanitize=thread -fPIC -DVIDARDB_TSAN_RUN
	PLATFORM_CXXFLAGS += -fsanitize=thread -fPIC -DVIDARDB_TSAN_RUN
        # Turn off -pg when enabling TSAN testing, because that induces
        # a link failure.  TODO: find the root cause
	PROFILING_FLAGS =
endif

# USAN doesn't work well with jemalloc. If we're compiling with USAN, we should use regular malloc.
ifdef COMPILE_WITH_UBSAN
	DISABLE_JEMALLOC=1
	EXEC_LDFLAGS += -fsanitize=undefined
	PLATFORM_CCFLAGS += -fsanitize=undefined
	PLATFORM_CXXFLAGS += -fsanitize=undefined
endif

ifndef DISABLE_JEMALLOC
	ifdef JEMALLOC
		PLATFORM_CXXFLAGS += "-DVIDARDB_JEMALLOC"
		PLATFORM_CCFLAGS +=  "-DVIDARDB_JEMALLOC"
	endif
	EXEC_LDFLAGS := $(JEMALLOC_LIB) $(EXEC_LDFLAGS)
	PLATFORM_CXXFLAGS += $(JEMALLOC_INCLUDE)
	PLATFORM_CCFLAGS += $(JEMALLOC_INCLUDE)
endif

export GTEST_THROW_ON_FAILURE=1 GTEST_HAS_EXCEPTIONS=1
GTEST_DIR = ./third-party/gtest-1.7.0/fused-src
PLATFORM_CCFLAGS += -isystem $(GTEST_DIR)
PLATFORM_CXXFLAGS += -isystem $(GTEST_DIR)

# This (the first rule) must depend on "all".
default: all

WARNING_FLAGS = -W -Wextra -Wall -Wsign-compare -Wshadow \
  -Wno-unused-parameter

ifndef DISABLE_WARNING_AS_ERROR
	WARNING_FLAGS += -Werror
endif

CFLAGS += $(WARNING_FLAGS) -I. -I./include $(PLATFORM_CCFLAGS) $(OPT)
CXXFLAGS += $(WARNING_FLAGS) -I. -I./include $(PLATFORM_CXXFLAGS) $(OPT) -Woverloaded-virtual -Wnon-virtual-dtor -Wno-missing-field-initializers

LDFLAGS += $(PLATFORM_LDFLAGS)

date := $(shell date +%F)
ifdef FORCE_GIT_SHA
	git_sha := $(FORCE_GIT_SHA)
else
	git_sha := $(shell git rev-parse HEAD 2>/dev/null)
endif
gen_build_version =							\
  printf '%s\n'								\
    '\#include "build_version.h"'					\
    'const char* vidardb_build_git_sha =				\
      "vidardb_build_git_sha:$(git_sha)";'			\
    'const char* vidardb_build_git_date =				\
      "vidardb_build_git_date:$(date)";'				\
    'const char* vidardb_build_compile_date = __DATE__;'

# Record the version of the source that we are compiling.
# We keep a record of the git revision in this file.  It is then built
# as a regular source file as part of the compilation process.
# One can run "strings executable_filename | grep _build_" to find
# the version of the source that we used to build the executable file.
CLEAN_FILES += util/build_version.cc:
FORCE:
util/build_version.cc: FORCE
	$(AM_V_GEN)rm -f $@-t
	$(AM_V_at)$(gen_build_version) > $@-t
	$(AM_V_at)if test -f $@; then					\
	  cmp -s $@-t $@ && rm -f $@-t || mv -f $@-t $@;		\
	else mv -f $@-t $@; fi

LIBOBJECTS = $(LIB_SOURCES:.cc=.o)
LIBOBJECTS += $(TOOL_SOURCES:.cc=.o)
MOCKOBJECTS = $(MOCK_SOURCES:.cc=.o)

GTEST = $(GTEST_DIR)/gtest/gtest-all.o
TESTUTIL = ./util/testutil.o
TESTHARNESS = ./util/testharness.o $(TESTUTIL) $(MOCKOBJECTS) $(GTEST)
VALGRIND_ERROR = 2
VALGRIND_VER := $(join $(VALGRIND_VER),valgrind)

VALGRIND_OPTS = --error-exitcode=$(VALGRIND_ERROR) --leak-check=full

BENCHTOOLOBJECTS = $(BENCH_SOURCES:.cc=.o) $(LIBOBJECTS) $(TESTUTIL)

TESTS = \
	db_test \
	db_test2 \
	db_block_cache_test \
	db_iter_test \
	db_log_iter_test \
	db_compaction_test \
	db_dynamic_level_test \
	db_iterator_test \
	db_sst_test \
	db_tailing_iter_test \
	db_universal_compaction_test \
	db_wal_test \
	db_io_failure_test \
	db_properties_test \
	db_table_properties_test \
	column_family_test \
	table_properties_collector_test \
	arena_test \
	auto_roll_logger_test \
	block_test \
	cache_test \
	coding_test \
	corruption_test \
	crc32c_test \
	dbformat_test \
	env_test \
	fault_injection_test \
	filelock_test \
	filename_test \
	file_reader_writer_test \
	histogram_test \
	inlineskiplist_test \
	log_test \
	manual_compaction_test \
	mock_env_test \
	memtable_list_test \
	merger_test \
	options_file_test \
	comparator_db_test \
	skiplist_test \
	version_edit_test \
	version_set_test \
	compaction_picker_test \
	version_builder_test \
	file_indexer_test \
	write_batch_test \
	write_controller_test\
	deletefile_test \
	table_test \
	thread_local_test \
	delete_scheduler_test \
	options_test \
	options_settable_test \
	event_logger_test \
	flush_job_test \
	wal_manager_test \
	listener_test \
	compaction_iterator_test \
	compaction_job_test \
	thread_list_test \
	compact_files_test \
	perf_context_test \
	heap_test \
	compaction_job_stats_test \
	iostats_context_test \
	repair_test\
	db_bench_tool_test\

PARALLEL_TEST = \
	backupable_db_test \
	db_compaction_test \
	db_test \
	db_universal_compaction_test \
	fault_injection_test \
	inlineskiplist_test \
	manual_compaction_test \
	table_test

SUBSET := $(TESTS)
ifdef VIDARDBTESTS_START
        SUBSET := $(shell echo $(SUBSET) | sed 's/^.*$(VIDARDBTESTS_START)/$(VIDARDBTESTS_START)/')
endif

ifdef VIDARDBTESTS_END
        SUBSET := $(shell echo $(SUBSET) | sed 's/$(VIDARDBTESTS_END).*//')
endif

TOOLS = \
	db_sanity_test \
	db_stress \
	write_stress \
	db_repl_stress

TEST_LIBS = \
	libvidardb_env_basic_test.a

# TODO: add back forward_iterator_bench, after making it build in all environemnts.
BENCHMARKS = db_bench table_reader_bench cache_bench memtablerep_bench

# if user didn't config LIBNAME, set the default
ifeq ($(LIBNAME),)
# we should only run vidardb in production with DEBUG_LEVEL 0
ifeq ($(DEBUG_LEVEL),0)
        LIBNAME=libvidardb
else
        LIBNAME=libvidardb_debug
endif
endif
LIBRARY = ${LIBNAME}.a
TOOLS_LIBRARY = ${LIBNAME}_tools.a

VIDARDB_MAJOR = $(shell egrep "VIDARDB_MAJOR.[0-9]" include/vidardb/version.h | cut -d ' ' -f 3)
VIDARDB_MINOR = $(shell egrep "VIDARDB_MINOR.[0-9]" include/vidardb/version.h | cut -d ' ' -f 3)
VIDARDB_PATCH = $(shell egrep "VIDARDB_PATCH.[0-9]" include/vidardb/version.h | cut -d ' ' -f 3)

default: all

#-----------------------------------------------
# Create platform independent shared libraries.
#-----------------------------------------------
ifneq ($(PLATFORM_SHARED_EXT),)

ifneq ($(PLATFORM_SHARED_VERSIONED),true)
SHARED1 = ${LIBNAME}.$(PLATFORM_SHARED_EXT)
SHARED2 = $(SHARED1)
SHARED3 = $(SHARED1)
SHARED4 = $(SHARED1)
SHARED = $(SHARED1)
else
SHARED_MAJOR = $(VIDARDB_MAJOR)
SHARED_MINOR = $(VIDARDB_MINOR)
SHARED_PATCH = $(VIDARDB_PATCH)
SHARED1 = ${LIBNAME}.$(PLATFORM_SHARED_EXT)
ifeq ($(PLATFORM), OS_MACOSX)
SHARED_OSX = $(LIBNAME).$(SHARED_MAJOR)
SHARED2 = $(SHARED_OSX).$(PLATFORM_SHARED_EXT)
SHARED3 = $(SHARED_OSX).$(SHARED_MINOR).$(PLATFORM_SHARED_EXT)
SHARED4 = $(SHARED_OSX).$(SHARED_MINOR).$(SHARED_PATCH).$(PLATFORM_SHARED_EXT)
else
SHARED2 = $(SHARED1).$(SHARED_MAJOR)
SHARED3 = $(SHARED1).$(SHARED_MAJOR).$(SHARED_MINOR)
SHARED4 = $(SHARED1).$(SHARED_MAJOR).$(SHARED_MINOR).$(SHARED_PATCH)
endif
SHARED = $(SHARED1) $(SHARED2) $(SHARED3) $(SHARED4)
$(SHARED1): $(SHARED4)
	ln -fs $(SHARED4) $(SHARED1)
$(SHARED2): $(SHARED4)
	ln -fs $(SHARED4) $(SHARED2)
$(SHARED3): $(SHARED4)
	ln -fs $(SHARED4) $(SHARED3)
endif

shared_libobjects = $(patsubst %,shared-objects/%,$(LIBOBJECTS))
CLEAN_FILES += shared-objects

$(shared_libobjects): shared-objects/%.o: %.cc
	$(AM_V_CC)mkdir -p $(@D) && $(CXX) $(CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) -c $< -o $@

$(SHARED4): $(shared_libobjects)
	$(CXX) $(PLATFORM_SHARED_LDFLAGS)$(SHARED3) $(CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) $(shared_libobjects) $(LDFLAGS) -o $@

endif  # PLATFORM_SHARED_EXT

.PHONY: blackbox_crash_test check clean coverage crash_test ldb_tests package \
	release tags valgrind_check whitebox_crash_test format static_lib shared_lib all \
	dbg  install install-static install-shared uninstall \
	analyze tools tools_lib docker-image hook_install

docker-image:
	@echo "Building docker image..."
	$(DOCKER) build --no-cache --pull --network $(NETWORK) \
		--build-arg apt_opts="$(APT_OPTS)" \
		--build-arg env_exts="$(ENV_EXTS)" \
		-t $(REGISTRY)/$(IMAGE):$(TAG) docker_image

all: $(LIBRARY) $(SHARED) $(BENCHMARKS) tools tools_lib test_libs  # Shichao

static_lib: $(LIBRARY)

shared_lib: $(SHARED)

tools: $(TOOLS)

tools_lib: $(TOOLS_LIBRARY)

test_libs: $(TEST_LIBS)

dbg: $(LIBRARY) $(BENCHMARKS) tools $(TESTS)

# creates static library and programs
release:
	$(MAKE) clean
	DEBUG_LEVEL=0 $(MAKE) static_lib tools db_bench

coverage:
	$(MAKE) clean
	COVERAGEFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS+="-lgcov" $(MAKE) J=1 all check
	cd coverage && ./coverage_test.sh
        # Delete intermediate files
	find . -type f -regex ".*\.\(\(gcda\)\|\(gcno\)\)" -exec rm {} \;

# install pre-commit hook, see CONTRIBUTING.md for the details
hook_install:
	@echo "Installing pre-commit hook..."
	./scripts/git-pre-commit-format install

ifneq (,$(filter check parallel_check,$(MAKECMDGOALS)),)
# Use /dev/shm if it has the sticky bit set (otherwise, /tmp),
# and create a randomly-named vidardb.XXXX directory therein.
# We'll use that directory in the "make check" rules.
ifeq ($(TMPD),)
TMPD := $(shell f=/dev/shm; test -k $$f || f=/tmp;			\
  perl -le 'use File::Temp "tempdir";'					\
    -e 'print tempdir("'$$f'/vidardb.XXXX", CLEANUP => 0)')
endif
endif

# Run all tests in parallel, accumulating per-test logs in t/log-*.
#
# Each t/run-* file is a tiny generated bourne shell script that invokes one of
# sub-tests. Why use a file for this?  Because that makes the invocation of
# parallel below simpler, which in turn makes the parsing of parallel's
# LOG simpler (the latter is for live monitoring as parallel
# tests run).
#
# Test names are extracted by running tests with --gtest_list_tests.
# This filter removes the "#"-introduced comments, and expands to
# fully-qualified names by changing input like this:
#
#   DBTest.
#     Empty
#     WriteEmptyBatch
#   MultiThreaded/MultiThreadedDBTest.
#     MultiThreaded/0  # GetParam() = 0
#     MultiThreaded/1  # GetParam() = 1
#
# into this:
#
#   DBTest.Empty
#   DBTest.WriteEmptyBatch
#   MultiThreaded/MultiThreadedDBTest.MultiThreaded/0
#   MultiThreaded/MultiThreadedDBTest.MultiThreaded/1
#

parallel_tests = $(patsubst %,parallel_%,$(PARALLEL_TEST))
.PHONY: gen_parallel_tests $(parallel_tests)
$(parallel_tests): $(PARALLEL_TEST)
	$(AM_V_at)TEST_BINARY=$(patsubst parallel_%,%,$@); \
  TEST_NAMES=` \
    ./$$TEST_BINARY --gtest_list_tests \
    | perl -n \
      -e 's/ *\#.*//;' \
      -e '/^(\s*)(\S+)/; !$$1 and do {$$p=$$2; break};'	\
      -e 'print qq! $$p$$2!'`; \
	for TEST_NAME in $$TEST_NAMES; do \
		TEST_SCRIPT=t/run-$$TEST_BINARY-$${TEST_NAME//\//-}; \
		echo "  GEN     " $$TEST_SCRIPT; \
    printf '%s\n' \
      '#!/bin/sh' \
      "d=\$(TMPD)$$TEST_SCRIPT" \
      'mkdir -p $$d' \
			"TEST_TMPDIR=\$$d ./$$TEST_BINARY --gtest_filter=$$TEST_NAME" \
		> $$TEST_SCRIPT; \
		chmod a=rx $$TEST_SCRIPT; \
	done

gen_parallel_tests:
	$(AM_V_at)mkdir -p t
	$(AM_V_at)rm -f t/run-*
	$(MAKE) $(parallel_tests)

# Reorder input lines (which are one per test) so that the
# longest-running tests appear first in the output.
# Do this by prefixing each selected name with its duration,
# sort the resulting names, and remove the leading numbers.
# FIXME: the "100" we prepend is a fake time, for now.
# FIXME: squirrel away timings from each run and use them
# (when present) on subsequent runs to order these tests.
#
# Without this reordering, these two tests would happen to start only
# after almost all other tests had completed, thus adding 100 seconds
# to the duration of parallel "make check".  That's the difference
# between 4 minutes (old) and 2m20s (new).
#
# 152.120 PASS t/DBTest.FileCreationRandomFailure
# 107.816 PASS t/DBTest.EncodeDecompressedBlockSizeTest
#
slow_test_regexp = \
	^t/run-table_test-HarnessTest.Randomized$$|^t/run-db_test-.*(?:FileCreationRandomFailure|EncodeDecompressedBlockSizeTest)$$
prioritize_long_running_tests =						\
  perl -pe 's,($(slow_test_regexp)),100 $$1,'				\
    | sort -k1,1gr							\
    | sed 's/^[.0-9]* //'

# "make check" uses
# Run with "make J=1 check" to disable parallelism in "make check".
# Run with "make J=200% check" to run two parallel jobs per core.
# The default is to run one job per core (J=100%).
# See "man parallel" for its "-j ..." option.
J ?= 100%

# Use this regexp to select the subset of tests whose names match.
tests-regexp = .

t_run = $(wildcard t/run-*)
.PHONY: check_0
check_0:
	$(AM_V_GEN)export TEST_TMPDIR=$(TMPD); \
	printf '%s\n' ''						\
	  'To monitor subtest <duration,pass/fail,name>,'		\
	  '  run "make watch-log" in a separate window' '';		\
	test -t 1 && eta=--eta || eta=; \
	{ \
		printf './%s\n' $(filter-out $(PARALLEL_TEST),$(TESTS)); \
		printf '%s\n' $(t_run); \
	} \
	  | $(prioritize_long_running_tests)				\
	  | grep -E '$(tests-regexp)'					\
	  | parallel -j$(J) --joblog=LOG $$eta --gnu '{} >& t/log-{/}'

.PHONY: valgrind_check_0
valgrind_check_0:
	$(AM_V_GEN)export TEST_TMPDIR=$(TMPD);				\
	printf '%s\n' ''						\
	  'To monitor subtest <duration,pass/fail,name>,'		\
	  '  run "make watch-log" in a separate window' '';		\
	test -t 1 && eta=--eta || eta=;					\
	{								\
	  printf './%s\n' $(filter-out $(PARALLEL_TEST) %skiplist_test options_settable_test, $(TESTS));		\
	  printf '%s\n' $(t_run);					\
	}								\
	  | $(prioritize_long_running_tests)				\
	  | grep -E '$(tests-regexp)'					\
	  | parallel -j$(J) --joblog=LOG $$eta --gnu \
      'if [[ "{}" == "./"* ]] ; then $(DRIVER) {} >& t/valgrind_log-{/}; ' \
      'else {} >& t/valgrind_log-{/}; fi'

CLEAN_FILES += t LOG $(TMPD)

# When running parallel "make check", you can monitor its progress
# from another window.
# Run "make watch_LOG" to show the duration,PASS/FAIL,name of parallel
# tests as they are being run.  We sort them so that longer-running ones
# appear at the top of the list and any failing tests remain at the top
# regardless of their duration. As with any use of "watch", hit ^C to
# interrupt.
watch-log:
	watch --interval=0 'sort -k7,7nr -k4,4gr LOG|$(quoted_perl_command)'

# If J != 1 and GNU parallel is installed, run the tests in parallel,
# via the check_0 rule above.  Otherwise, run them sequentially.
check: all
	$(MAKE) gen_parallel_tests
	$(AM_V_GEN)if test "$(J)" != 1                                  \
	    && (parallel --gnu --help 2>/dev/null) |                    \
	        grep -q 'GNU Parallel';                                 \
	then                                                            \
	    $(MAKE) T="$$t" TMPD=$(TMPD) check_0;                       \
	else                                                            \
	    for t in $(TESTS); do                                       \
	      echo "===== Running $$t"; ./$$t || exit 1; done;          \
	fi
	rm -rf $(TMPD)
ifeq ($(filter -DVIDARDB_LITE,$(OPT)),)
	python tools/ldb_test.py
	sh tools/vidardb_dump_test.sh
endif

check_some: $(SUBSET) ldb_tests
	for t in $(SUBSET); do echo "===== Running $$t"; ./$$t || exit 1; done

.PHONY: ldb_tests
ldb_tests: ldb
	python tools/ldb_test.py

crash_test: whitebox_crash_test blackbox_crash_test

blackbox_crash_test: db_stress
	python -u tools/db_crashtest.py --simple blackbox
	python -u tools/db_crashtest.py blackbox

whitebox_crash_test: db_stress
	python -u tools/db_crashtest.py --simple whitebox
	python -u tools/db_crashtest.py whitebox

asan_check:
	$(MAKE) clean
	COMPILE_WITH_ASAN=1 $(MAKE) check -j32
	$(MAKE) clean

asan_crash_test:
	$(MAKE) clean
	COMPILE_WITH_ASAN=1 $(MAKE) crash_test
	$(MAKE) clean

ubsan_check:
	$(MAKE) clean
	COMPILE_WITH_UBSAN=1 $(MAKE) check -j32
	$(MAKE) clean

ubsan_crash_test:
	$(MAKE) clean
	COMPILE_WITH_UBSAN=1 $(MAKE) crash_test
	$(MAKE) clean

valgrind_check: $(TESTS)
	$(MAKE) gen_parallel_tests
	$(AM_V_GEN)if test "$(J)" != 1                                  \
	    && (parallel --gnu --help 2>/dev/null) |                    \
	        grep -q 'GNU Parallel';                                 \
	then                                                            \
      $(MAKE) TMPD=$(TMPD)                                        \
      DRIVER="$(VALGRIND_VER) $(VALGRIND_OPTS)" valgrind_check_0; \
	else                                                            \
		for t in $(filter-out %skiplist_test options_settable_test,$(TESTS)); do \
			$(VALGRIND_VER) $(VALGRIND_OPTS) ./$$t; \
			ret_code=$$?; \
			if [ $$ret_code -ne 0 ]; then \
				exit $$ret_code; \
			fi; \
		done; \
	fi


ifneq ($(PAR_TEST),)
parloop:
	ret_bad=0;							\
	for t in $(PAR_TEST); do		\
		echo "===== Running $$t in parallel $(NUM_PAR)";\
		if [ $(db_test) -eq 1 ]; then \
			seq $(J) | v="$$t" parallel --gnu 's=$(TMPD)/rdb-{};  export TEST_TMPDIR=$$s;' \
				'timeout 2m ./db_test --gtest_filter=$$v >> $$s/log-{} 2>1'; \
		else\
			seq $(J) | v="./$$t" parallel --gnu 's=$(TMPD)/rdb-{};' \
			     'export TEST_TMPDIR=$$s; timeout 10m $$v >> $$s/log-{} 2>1'; \
		fi; \
		ret_code=$$?; \
		if [ $$ret_code -ne 0 ]; then \
			ret_bad=$$ret_code; \
			echo $$t exited with $$ret_code; \
		fi; \
	done; \
	exit $$ret_bad;
endif

test_names = \
  ./db_test --gtest_list_tests						\
    | perl -n								\
      -e 's/ *\#.*//;'							\
      -e '/^(\s*)(\S+)/; !$$1 and do {$$p=$$2; break};'			\
      -e 'print qq! $$p$$2!'

parallel_check: $(TESTS)
	$(AM_V_GEN)if test "$(J)" > 1                                  \
	    && (parallel --gnu --help 2>/dev/null) |                    \
	        grep -q 'GNU Parallel';                                 \
	then                                                            \
	    echo Running in parallel $(J);			\
	else                                                            \
	    echo "Need to have GNU Parallel and J > 1"; exit 1;		\
	fi;								\
	ret_bad=0;							\
	echo $(J);\
	echo Test Dir: $(TMPD); \
        seq $(J) | parallel --gnu 's=$(TMPD)/rdb-{}; rm -rf $$s; mkdir $$s'; \
	$(MAKE)  PAR_TEST="$(shell $(test_names))" TMPD=$(TMPD) \
		J=$(J) db_test=1 parloop; \
	$(MAKE) PAR_TEST="$(filter-out db_test, $(TESTS))" \
		TMPD=$(TMPD) J=$(J) db_test=0 parloop;

analyze: clean
	$(CLANG_SCAN_BUILD) --use-analyzer=$(CLANG_ANALYZER) \
		--use-c++=$(CXX) --use-cc=$(CC) --status-bugs \
		-o $(CURDIR)/scan_build_report \
		$(MAKE) dbg

CLEAN_FILES += unity.cc
unity.cc: Makefile
	rm -f $@ $@-t
	for source_file in $(LIB_SOURCES); do \
		echo "#include \"$$source_file\"" >> $@-t; \
	done
	chmod a=r $@-t
	mv $@-t $@

unity.a: unity.o
	$(AM_V_AR)rm -f $@
	$(AM_V_at)$(AR) $(ARFLAGS) $@ unity.o

# try compiling db_test with unity
unity_test: test/db/db_test.o test/db/db_test_util.o $(TESTHARNESS) unity.a
	$(AM_LINK)
	./unity_test

vidardb.h vidardb.cc: build_tools/amalgamate.py Makefile $(LIB_SOURCES) unity.cc
	build_tools/amalgamate.py -I. -i./include unity.cc -x include/vidardb/c.h -H vidardb.h -o vidardb.cc

clean:
	rm -f $(BENCHMARKS) $(TOOLS) $(TESTS) $(LIBRARY) $(SHARED)
	rm -rf $(CLEAN_FILES) ios-x86 ios-arm scan_build_report
	find . -name "*.[oda]" -exec rm -f {} \;
	find . -name "*.so*" -exec rm -f {} \;
	find . -type f -regex ".*\.\(\(gcda\)\|\(gcno\)\)" -exec rm {} \;
	rm -rf bzip2* snappy* zlib* lz4*

tags:
	ctags * -R
	cscope -b `find . -name '*.cc'` `find . -name '*.h'` `find . -name '*.c'`

# ---------------------------------------------------------------------------
# 	Unit tests and tools
# ---------------------------------------------------------------------------
$(LIBRARY): $(LIBOBJECTS)
	$(AM_V_AR)rm -f $@
	$(AM_V_at)$(AR) $(ARFLAGS) $@ $(LIBOBJECTS)

$(TOOLS_LIBRARY): $(BENCH_SOURCES:.cc=.o) $(TOOL_SOURCES:.cc=.o) $(LIB_SOURCES:.cc=.o) $(TESTUTIL)
	$(AM_V_AR)rm -f $@
	$(AM_V_at)$(AR) $(ARFLAGS) $@ $^

libvidardb_env_basic_test.a: $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_V_AR)rm -f $@
	$(AM_V_at)$(AR) $(ARFLAGS) $@ $^

db_bench: tools/db_bench.o $(BENCHTOOLOBJECTS)
	$(AM_LINK)

cache_bench: tools/cache_bench.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

memtablerep_bench: tools/memtablerep_bench.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

db_stress: tools/db_stress.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

write_stress: tools/write_stress.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

db_sanity_test: test/tools/db_sanity_test.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

db_repl_stress: tools/db_repl_stress.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

arena_test: test/util/arena_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

column_family_test: test/db/column_family_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

table_properties_collector_test: test/db/table_properties_collector_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

cache_test: test/util/cache_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

coding_test: test/util/coding_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

histogram_test: test/util/histogram_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

thread_local_test: test/util/thread_local_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

corruption_test: test/db/corruption_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

crc32c_test: test/util/crc32c_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_test: test/db/db_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_test2: test/db/db_test2.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_block_cache_test: test/db/db_block_cache_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_log_iter_test: test/db/db_log_iter_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_compaction_test: test/db/db_compaction_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_dynamic_level_test: test/db/db_dynamic_level_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_iterator_test: test/db/db_iterator_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_sst_test: test/db/db_sst_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_tailing_iter_test: test/db/db_tailing_iter_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_iter_test: test/db/db_iter_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_universal_compaction_test: test/db/db_universal_compaction_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_wal_test: test/db/db_wal_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_io_failure_test: test/db/db_io_failure_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_properties_test: test/db/db_properties_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_table_properties_test: test/db/db_table_properties_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

log_write_bench: util/log_write_bench.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK) $(PROFILING_FLAGS)

comparator_db_test: test/db/comparator_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

table_reader_bench: table/table_reader_bench.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK) $(PROFILING_FLAGS)

perf_context_test: test/db/perf_context_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_V_CCLD)$(CXX) $^ $(EXEC_LDFLAGS) -o $@ $(LDFLAGS)

env_mirror_test: test/utilities/env_mirror_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

env_registry_test: test/utilities/env_registry_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

flush_job_test: test/db/flush_job_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compaction_iterator_test: test/db/compaction_iterator_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compaction_job_test: test/db/compaction_job_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compaction_job_stats_test: test/db/compaction_job_stats_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

wal_manager_test: test/db/wal_manager_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

dbformat_test: test/db/dbformat_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

env_basic_test: test/util/env_basic_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

env_test: test/util/env_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

fault_injection_test: test/db/fault_injection_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

delete_scheduler_test: test/util/delete_scheduler_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

filename_test: test/db/filename_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

file_reader_writer_test: test/util/file_reader_writer_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

log_test: test/db/log_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

table_test: test/table/table_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

block_test: test/table/block_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

inlineskiplist_test: test/db/inlineskiplist_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

skiplist_test: test/db/skiplist_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

version_edit_test: test/db/version_edit_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

version_set_test: test/db/version_set_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compaction_picker_test: test/db/compaction_picker_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

version_builder_test: test/db/version_builder_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

file_indexer_test: test/db/file_indexer_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

write_batch_test: test/db/write_batch_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

write_controller_test: test/db/write_controller_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

merger_test: test/table/merger_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

options_file_test: test/db/options_file_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

deletefile_test: test/db/deletefile_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

geodb_test: test/utilities/geodb/geodb_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

vidardb_undump: tools/dump/vidardb_undump.o $(LIBOBJECTS)
	$(AM_LINK)

listener_test: test/db/listener_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

thread_list_test: test/util/thread_list_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compact_files_test: test/db/compact_files_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

options_test: test/util/options_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

options_settable_test: test/util/options_settable_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_bench_tool_test: test/tools/db_bench_tool_test.o $(BENCHTOOLOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

event_logger_test: test/util/event_logger_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

mock_env_test : test/util/mock_env_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

manual_compaction_test: test/db/manual_compaction_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

filelock_test: test/util/filelock_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

auto_roll_logger_test: test/db/auto_roll_logger_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

memtable_list_test: test/memtable/memtable_list_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

heap_test: test/util/heap_test.o $(GTEST)
	$(AM_LINK)

repair_test: test/db/repair_test.o test/db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

iostats_context_test: test/util/iostats_context_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_V_CCLD)$(CXX) $^ $(EXEC_LDFLAGS) -o $@ $(LDFLAGS)

#-------------------------------------------------
# make install related stuff
INSTALL_PATH ?= /usr/local

uninstall:
	rm -rf $(INSTALL_PATH)/include/vidardb \
	  $(INSTALL_PATH)/lib/$(LIBRARY) \
	  $(INSTALL_PATH)/lib/$(SHARED4) \
	  $(INSTALL_PATH)/lib/$(SHARED3) \
	  $(INSTALL_PATH)/lib/$(SHARED2) \
	  $(INSTALL_PATH)/lib/$(SHARED1)

install-headers:
	install -d $(INSTALL_PATH)/lib
	for header_dir in `find "include/vidardb" -type d`; do \
		install -d $(INSTALL_PATH)/$$header_dir; \
	done
	for header in `find "include/vidardb" -type f -name *.h`; do \
		install -C -m 644 $$header $(INSTALL_PATH)/$$header; \
	done

install-static: install-headers $(LIBRARY)
	install -C -m 755 $(LIBRARY) $(INSTALL_PATH)/lib

install-shared: install-headers $(SHARED4)
	install -C -m 755 $(SHARED4) $(INSTALL_PATH)/lib && \
		ln -fs $(SHARED4) $(INSTALL_PATH)/lib/$(SHARED3) && \
		ln -fs $(SHARED4) $(INSTALL_PATH)/lib/$(SHARED2) && \
		ln -fs $(SHARED4) $(INSTALL_PATH)/lib/$(SHARED1)

# install both static and shared library by cmake
install:
	@echo "install both static and shared library by cmake ..."
	CMAKE_FLAGS=$(CMAKE_FLAGS) ./CMakeInstall.sh

#-------------------------------------------------


# ---------------------------------------------------------------------------
#  	Platform-specific compilation
# ---------------------------------------------------------------------------

ifeq ($(PLATFORM), IOS)
# For iOS, create universal object files to be used on both the simulator and
# a device.
PLATFORMSROOT=/Applications/Xcode.app/Contents/Developer/Platforms
SIMULATORROOT=$(PLATFORMSROOT)/iPhoneSimulator.platform/Developer
DEVICEROOT=$(PLATFORMSROOT)/iPhoneOS.platform/Developer
IOSVERSION=$(shell defaults read $(PLATFORMSROOT)/iPhoneOS.platform/version CFBundleShortVersionString)

.cc.o:
	mkdir -p ios-x86/$(dir $@)
	$(CXX) $(CXXFLAGS) -isysroot $(SIMULATORROOT)/SDKs/iPhoneSimulator$(IOSVERSION).sdk -arch i686 -arch x86_64 -c $< -o ios-x86/$@
	mkdir -p ios-arm/$(dir $@)
	xcrun -sdk iphoneos $(CXX) $(CXXFLAGS) -isysroot $(DEVICEROOT)/SDKs/iPhoneOS$(IOSVERSION).sdk -arch armv6 -arch armv7 -arch armv7s -arch arm64 -c $< -o ios-arm/$@
	lipo ios-x86/$@ ios-arm/$@ -create -output $@

.c.o:
	mkdir -p ios-x86/$(dir $@)
	$(CC) $(CFLAGS) -isysroot $(SIMULATORROOT)/SDKs/iPhoneSimulator$(IOSVERSION).sdk -arch i686 -arch x86_64 -c $< -o ios-x86/$@
	mkdir -p ios-arm/$(dir $@)
	xcrun -sdk iphoneos $(CC) $(CFLAGS) -isysroot $(DEVICEROOT)/SDKs/iPhoneOS$(IOSVERSION).sdk -arch armv6 -arch armv7 -arch armv7s -arch arm64 -c $< -o ios-arm/$@
	lipo ios-x86/$@ ios-arm/$@ -create -output $@

else
.cc.o:
	$(AM_V_CC)$(CXX) $(CXXFLAGS) -c $< -o $@ $(COVERAGEFLAGS)

.c.o:
	$(AM_V_CC)$(CC) $(CFLAGS) -c $< -o $@
endif

# ---------------------------------------------------------------------------
#  	Source files dependencies detection
# ---------------------------------------------------------------------------

all_sources = $(LIB_SOURCES) $(TEST_BENCH_SOURCES) $(MOCK_SOURCES)
DEPFILES = $(all_sources:.cc=.d)

# Add proper dependency support so changing a .h file forces a .cc file to
# rebuild.

# The .d file indicates .cc file's dependencies on .h files. We generate such
# dependency by g++'s -MM option, whose output is a make dependency rule.
$(DEPFILES): %.d: %.cc
	@$(CXX) $(CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) \
	  -MM -MT'$@' -MT'$(<:.cc=.o)' "$<" -o '$@'

depend: $(DEPFILES)

# if the make goal is either "clean" or "format", we shouldn't
# try to import the *.d files.
# TODO(kailiu) The unfamiliarity of Make's conditions leads to the ugly
# working solution.
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),format)
ifneq ($(MAKECMDGOALS),jclean)
ifneq ($(MAKECMDGOALS),jtest)
ifneq ($(MAKECMDGOALS),package)
ifneq ($(MAKECMDGOALS),analyze)
-include $(DEPFILES)
endif
endif
endif
endif
endif
endif
