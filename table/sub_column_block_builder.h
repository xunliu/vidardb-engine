//  Copyright (c) 2019-present, VidarDB, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.

#pragma once

#include <limits>

#include "table/block_builder.h"

namespace vidardb {

// Sub-column builder
class SubColumnBlockBuilder : public BlockBuilder {
 public:
  SubColumnBlockBuilder(const SubColumnBlockBuilder&) = delete;
  void operator=(const SubColumnBlockBuilder&) = delete;

  explicit SubColumnBlockBuilder(int block_restart_interval)
      : BlockBuilder(block_restart_interval),
        fixed_length_(std::numeric_limits<uint32_t>::max()) {}

  virtual ~SubColumnBlockBuilder() {}

  // Reset the contents as if the BlockBuilder was just constructed.
  virtual void Reset() override;

  // REQUIRES: Finish() has not been called since the last call to Reset().
  // REQUIRES: key is larger than any previously added key
  virtual void Add(const Slice& key, const Slice& value) override;

  // Finish building the block and return a slice that refers to the
  // block contents.  The returned slice will remain valid for the
  // lifetime of this builder or until Reset() is called.
  virtual Slice Finish() override;

  // Returns an estimate of the current (uncompressed) size of the block
  // we are building.
  virtual size_t CurrentSizeEstimate() const override;

  // Returns an estimated block size after appending key and value.
  virtual size_t EstimateSizeAfterKV(const Slice& key,
                                     const Slice& value) const override;

  // Called after Add
  virtual bool IsKeyStored() const override {
    return counter_ == 1;
  }

 private:
  // max means value length varies, otherwise it is fixed
  uint32_t fixed_length_;
};

}  // namespace vidardb
