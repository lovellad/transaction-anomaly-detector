
-- Step 1: for each day, summarise the same day-of-month in the previous 8 months
WITH baseline AS (
    SELECT
        date,
        day_of_month,
        txn_volume,
        AVG(txn_volume)         OVER same_day_history AS baseline_mean,
        STDDEV_SAMP(txn_volume) OVER same_day_history AS baseline_std,
        COUNT(txn_volume)       OVER same_day_history AS n_history
    FROM df
    WINDOW same_day_history AS (
        PARTITION BY day_of_month              -- group all the 1sts, all the 2nds...
        ORDER BY date
        ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING  -- previous 8, not including today
    )
),

-- Step 2: how unusual is today compared with its history?
scored AS (
    SELECT
        *,
        (txn_volume - baseline_mean) / NULLIF(baseline_std, 0) AS z_score
    FROM baseline
)

-- Step 3: label each day
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