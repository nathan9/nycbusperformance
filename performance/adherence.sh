# adherence.sql

SET @start_date = '2014-10-16';
SET @end_date = '2014-10-31';

REPLACE adherence
	SELECT
		sched_dep_date,
		sched_dep_hour,
		route_id,
		direction_id,
		stop_id,
		SUM(IF(TIMEDIFF(sched_dep_utc, est_dep_utc) > '00:01:00', 1, 0)) AS early,
		SUM(IF(TIMEDIFF(sched_dep_utc, est_dep_utc) <= '00:01:00', IF(TIMEDIFF(est_dep_utc, sched_dep_utc) <= '00:05:00', 1, 0), 0)) AS on_time,
		SUM(IF(TIMEDIFF(est_dep_utc, sched_dep_utc) > '00:05:00', 1, 0)) AS late
	FROM events
	WHERE (sched_dep_date BETWEEN @start_date AND @end_date AND dep_accuracy < 60
	GROUP BY sched_dep_date, sched_dep_hour, route_id, direction_id, stop_id;

