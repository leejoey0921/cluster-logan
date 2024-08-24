\time zstdcat diamond_all_batch.log.zst|grep -v "^2024-07-0[15]" |grep "\(signal\)\|\(Done\)" |zstd -c > diamond_all_batch.log.reduced.zst
