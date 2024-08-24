\time aws logs tail /aws/batch/job --since 125d | zstd -c > diamond_all_batch.log.bigone.zst
# interrupted the cmd above when i started seeing july logs
zstdcat diamond_all_batch.log.bigone.zst|grep -v "^2024-07" |zstd -c > diamond_all_batch.log.beforejuly.zst

