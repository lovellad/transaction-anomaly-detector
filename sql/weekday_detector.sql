
-- Same z-score method, but the baseline is the same weekday over the previous 8 weeks
WITH baseline AS (
    SELECT
        date,
        dayname(date) AS weekday,
        txn_volume,
        AVG(txn_volume)         OVER same_weekday_history AS baseline_mean,
        STDDEV_SAMP(txn_volume) OVER same_weekday_history AS baseline_std,
        COUNT(txn_volume)       OVER same_weekday_history AS n_history
    FROM df
    WINDOW same_weekday_history AS (
        PARTITION BY dayofweek(date)               -- group all Mondays, all Tuesdays...
        ORDER BY date
        ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING   -- previous 8 weeks
    )
),
scored AS (
    SELECT
        *,
        (txn_volume - baseline_mean) / NULLIF(baseline_std, 0) AS z_score
    FROM baseline
)
SELECT
    *,
    CASE
        WHEN n_history < 4      THEN 'NOT_ENOUGH_HISTORY'
        WHEN ABS(z_score) >= 3  THEN 'CRITICAL'
        WHEN ABS(z_score) >= 2  THEN 'WARNING'
        ELSE 'NORMAL'
    END AS status
FROM scored
ORDER BY date