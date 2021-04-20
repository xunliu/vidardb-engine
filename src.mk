# These are the sources from which libvidardb.a is built:
LIB_SOURCES =                                                   \
  db/auto_roll_logger.cc                                        \
  db/builder.cc                                                 \
  db/column_family.cc                                           \
  db/compaction.cc                                              \
  db/compaction_iterator.cc                                     \
  db/compaction_job.cc                                          \
  db/compaction_picker.cc                                       \
  db/convenience.cc                                             \
  db/db_filesnapshot.cc                                         \
  db/dbformat.cc                                                \
  db/db_impl.cc                                                 \
  db/db_impl_debug.cc                                           \
  db/db_impl_readonly.cc                                        \
  db/db_info_dumper.cc                                          \
  db/db_iter.cc                                                 \
  db/event_helpers.cc                                           \
  db/file_indexer.cc                                            \
  db/file_iter.cc                                               \
  db/filename.cc                                                \
  db/flush_job.cc                                               \
  db/flush_scheduler.cc                                         \
  db/forward_iterator.cc                                        \
  db/internal_stats.cc                                          \
  db/log_reader.cc                                              \
  db/log_writer.cc                                              \
  memtable/memtable_allocator.cc                                \
  memtable/memtable.cc                                          \
  memtable/memtable_list.cc                                     \
  db/repair.cc                                                  \
  db/snapshot_impl.cc                                           \
  db/table_cache.cc                                             \
  db/table_properties_collector.cc                              \
  db/transaction_log_impl.cc                                    \
  db/version_builder.cc                                         \
  db/version_edit.cc                                            \
  db/version_set.cc                                             \
  db/wal_manager.cc                                             \
  db/write_batch.cc                                             \
  db/write_controller.cc                                        \
  db/write_thread.cc                                            \
  memtable/skiplistrep.cc                                       \
  memtable/vectorrep.cc                                         \
  port/stack_trace.cc                                           \
  port/port_posix.cc                                            \
  table/adaptive_table_factory.cc                               \
  table/block_based_table_builder.cc                            \
  table/block_based_table_factory.cc                            \
  table/block_based_table_reader.cc                             \
  table/column_table_builder.cc                                 \
  table/column_table_factory.cc                                 \
  table/column_table_reader.cc                                  \
  table/block_builder.cc                                        \
  table/block.cc                                                \
  table/column_block_builder.cc                                 \
  table/min_max_block_builder.cc                                \
  table/flush_block_policy.cc                                   \
  table/format.cc                                               \
  table/get_context.cc                                          \
  table/iterator.cc                                             \
  table/merger.cc                                               \
  table/meta_blocks.cc                                          \
  table/sst_file_writer.cc                                      \
  table/table_properties.cc                                     \
  table/two_level_iterator.cc                                   \
  util/arena.cc                                                 \
  util/build_version.cc                                         \
  util/cache.cc                                                 \
  util/coding.cc                                                \
  util/comparator.cc                                            \
  util/splitter.cc                                              \
  util/compaction_job_stats_impl.cc                             \
  util/concurrent_arena.cc                                      \
  util/crc32c.cc                                                \
  util/delete_scheduler.cc                                      \
  util/env.cc                                                   \
  util/env_posix.cc                                             \
  util/io_posix.cc                                              \
  util/threadpool.cc                                            \
  util/sst_file_manager_impl.cc                                 \
  util/file_util.cc                                             \
  util/file_reader_writer.cc                                    \
  util/hash.cc                                                  \
  util/histogram.cc                                             \
  util/instrumented_mutex.cc                                    \
  util/iostats_context.cc                                       \
  util/event_logger.cc                                          \
  util/log_buffer.cc                                            \
  util/logging.cc                                               \
  util/murmurhash.cc                                            \
  util/mutable_cf_options.cc                                    \
  util/options.cc                                               \
  util/options_helper.cc                                        \
  util/options_parser.cc                                        \
  util/options_sanity_check.cc                                  \
  util/perf_context.cc                                          \
  util/perf_level.cc                                            \
  util/random.cc                                                \
  util/slice.cc                                                 \
  util/statistics.cc                                            \
  util/status.cc                                                \
  util/status_message.cc                                        \
  util/string_util.cc                                           \
  util/sync_point.cc                                            \
  util/thread_local.cc                                          \
  util/thread_status_impl.cc                                    \
  util/thread_status_updater.cc                                 \
  util/thread_status_updater_debug.cc                           \
  util/thread_status_util.cc                                    \
  util/thread_status_util_debug.cc                              \
  utilities/write_batch_with_index/write_batch_with_index.cc    \
  utilities/write_batch_with_index/write_batch_with_index_internal.cc    \
  utilities/transactions/transaction_db_mutex_impl.cc           \
  utilities/transactions/transaction_util.cc                    \
  utilities/transactions/transaction_base.cc                    \
  utilities/transactions/transaction_impl.cc                    \
  utilities/transactions/transaction_lock_mgr.cc                \
  utilities/transactions/transaction_db_impl.cc                 \

TOOL_SOURCES = \

MOCK_SOURCES = \
  table/mock_table.cc \
  util/mock_env.cc \
  util/fault_injection_test_env.cc

BENCH_SOURCES = \
  tools/db_bench_tool.cc

TEST_BENCH_SOURCES =                                                         \
  third-party/gtest-1.7.0/fused-src/gtest/gtest-all.cc                       \
  test/db/auto_roll_logger_test.cc                                           \
  test/db/column_family_test.cc                                              \
  test/db/compaction_job_test.cc                                             \
  test/db/compaction_job_stats_test.cc                                       \
  test/db/compaction_picker_test.cc                                          \
  test/db/comparator_db_test.cc                                              \
  test/db/corruption_test.cc                                                 \
  tools/db_bench_tool.cc                                                     \
  test/db/dbformat_test.cc                                                   \
  test/db/db_iter_test.cc                                                    \
  test/db/db_test.cc                                                         \
  test/db/db_block_cache_test.cc                                             \
  test/db/db_io_failure_test.cc                                              \
  test/db/db_compaction_test.cc                                              \
  test/db/db_dynamic_level_test.cc                                           \
  test/db/db_iterator_test.cc                                                \
  test/db/db_log_iter_test.cc                                                \
  test/db/db_sst_test.cc                                                     \
  test/db/db_tailing_iter_test.cc                                            \
  test/db/db_universal_compaction_test.cc                                    \
  test/db/db_wal_test.cc                                                     \
  test/db/db_table_properties_test.cc                                        \
  test/db/deletefile_test.cc                                                 \
  test/db/fault_injection_test.cc                                            \
  test/db/file_indexer_test.cc                                               \
  test/db/filename_test.cc                                                   \
  test/db/flush_job_test.cc                                                  \
  test/db/inlineskiplist_test.cc                                             \
  test/db/listener_test.cc                                                   \
  test/db/log_test.cc                                                        \
  test/db/manual_compaction_test.cc                                          \
  tools/memtablerep_bench.cc                                              \
  test/db/options_file_test.cc                                               \
  test/db/perf_context_test.cc                                               \
  test/db/skiplist_test.cc                                                   \
  test/db/table_properties_collector_test.cc                                 \
  db/db_test_util.cc                                                         \
  test/db/version_builder_test.cc                                            \
  test/db/version_edit_test.cc                                               \
  test/db/version_set_test.cc                                                \
  test/db/wal_manager_test.cc                                                \
  test/db/write_batch_test.cc                                                \
  test/db/write_controller_test.cc                                           \
  test/table/block_test.cc                                                   \
  test/table/merger_test.cc                                                  \
  table/table_reader_bench.cc                                                \
  test/table/table_test.cc                                                   \
  test/tools/db_bench_tool_test.cc                                           \
  test/tools/db_sanity_test.cc                                               \
  test/util/arena_test.cc                                                    \
  test/util/cache_bench.cc                                                   \
  test/util/cache_test.cc                                                    \
  test/util/coding_test.cc                                                   \
  test/util/crc32c_test.cc                                                   \
  test/util/env_test.cc                                                      \
  test/util/filelock_test.cc                                                 \
  test/util/histogram_test.cc                                                \
  test/utilities/env_registry_test.cc                                        \
  test/util/iostats_context_test.cc                                          \
  util/log_write_bench.cc                                                    \
  test/util/mock_env_test.cc                                                 \
  test/util/options_test.cc                                                  \
  test/util/event_logger_test.cc                                             \
  test/util/testharness.cc                                                   \
  test/util/testutil.cc                                                      \
  test/util/thread_list_test.cc                                              \
  test/util/thread_local_test.cc
