SELECT 
    x.id,
    x.last_notification_hour, 
    x.hours
FROM
(
    SELECT 
        *, 
        FLOOR(((CAST(EXTRACT(epoch FROM NOW()) AS INT) - last_meal_at) / 3600)) as hours 
    FROM user_fasting_timers
) AS x
where x.hours > x.last_notification_hour;