\time aws logs tail /aws/batch/job --since 40d | zstd -c > diamond_all_batch.log.zst
