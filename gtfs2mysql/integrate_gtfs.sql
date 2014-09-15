# integrate_gtfs.sql
# Add GTFS data to collection of feeds in MySQL and assign integer indexes.

SELECT MAX(feed_index) FROM feeds INTO @feed_index;

INSERT agency
        SELECT @feed_index, NULL, TRIM(agency_id), TRIM(agency_name), TRIM(agency_url), TRIM(agency_timezone), TRIM(agency_lang)
        FROM tmp_agency;

INSERT calendar
        SELECT @feed_index, NULL, TRIM(service_id), CONCAT(TRIM(monday), TRIM(tuesday), TRIM(wednesday), TRIM(thursday), TRIM(friday), TRIM(saturday), TRIM(sunday)), start_date, end_date
        FROM tmp_calendar;

# Add calendar_dates.txt and set the service_index to -1 unless service_index already assigned to the service_id in calendar.txt.
INSERT calendar_dates
        SELECT @feed_index, COALESCE(service_index, -1), TRIM(tcd.service_id), date, exception_type
        FROM tmp_calendar_dates tcd
        LEFT JOIN calendar c
        ON feed_index = @feed_index AND
           c.service_id = TRIM(tcd.service_id);

# Assign new service_indexes where service_id not in calendar.
SELECT COALESCE(MAX(service_index), 0) FROM calendar INTO @service_index;
SET @last_service_id = '';
UPDATE calendar_dates
        SET service_index = IF(service_id != @last_service_id, @service_index := @service_index + 1, @service_index),
            service_id = @last_service_id := service_id
        WHERE feed_index = @feed_index AND service_index = -1
        ORDER BY service_id;

CREATE TEMPORARY TABLE service_indexes (
        feed_index smallint NOT NULL,
        service_id varchar(255) NOT NULL,
        service_index int NOT NULL,
        PRIMARY KEY (feed_index, service_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT service_indexes
	SELECT @feed_index, service_id, service_index FROM calendar WHERE feed_index = @feed_index
        UNION DISTINCT
        SELECT @feed_index, service_id, service_index FROM calendar_dates WHERE feed_index = @feed_index AND exception_type = 1;

INSERT routes
        SELECT @feed_index, NULL, TRIM(route_id), agency_index, TRIM(route_short_name), TRIM(route_long_name), TRIM(route_desc), route_type, TRIM(route_url), TRIM(route_color), TRIM(route_text_color)
        FROM agency a, tmp_routes tr
        WHERE a.feed_index = @feed_index AND a.agency_id = TRIM(tr.agency_id);

SELECT COALESCE(MAX(shape_index), 0) FROM shapes INTO @shape_index;
SET @last_shape_id = '';
INSERT shapes
        SELECT @feed_index, IF(TRIM(shape_id) != @last_shape_id, @shape_index := @shape_index + 1, @shape_index), @last_shape_id := TRIM(shape_id), ROUND(shape_pt_lat, 6), ROUND(shape_pt_lon, 6), shape_pt_sequence
        FROM tmp_shapes
        ORDER BY TRIM(shape_id), shape_pt_sequence;

CREATE TEMPORARY TABLE shape_indexes (
        feed_index smallint NOT NULL,
        shape_id varchar(255) NOT NULL,
        shape_index int NOT NULL,
        PRIMARY KEY (feed_index, shape_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT shape_indexes
        SELECT @feed_index, shape_id, shape_index FROM shapes GROUP BY shape_id;

INSERT stops
        SELECT @feed_index, NULL, TRIM(stop_id), TRIM(stop_name), TRIM(stop_desc), ROUND(stop_lat, 6), ROUND(stop_lon, 6)
        FROM tmp_stops;

INSERT trips
        SELECT @feed_index, NULL, route_index, service_index, TRIM(trip_id), TRIM(trip_headsign), direction_id, shape_index
        FROM tmp_trips tt, routes r, service_indexes c, shape_indexes s
        WHERE (r.feed_index = @feed_index AND r.route_id = TRIM(tt.route_id)) AND
              (c.feed_index = @feed_index AND c.service_id = TRIM(tt.service_id)) AND
              (s.feed_index = @feed_index AND s.shape_id = TRIM(tt.shape_id));

INSERT stop_times
        SELECT trip_index, arrival_time, departure_time, stop_index, stop_sequence, pickup_type, drop_off_type
        FROM tmp_stop_times tst, trips t, stops s
        WHERE (t.feed_index = @feed_index AND t.trip_id = TRIM(tst.trip_id)) AND
              (s.feed_index = @feed_index AND s.stop_id = TRIM(tst.stop_id));

INSERT service_indexes_per_date
	SELECT @feed_index, date, service_index FROM calendar, dates WHERE feed_index = @feed_index AND (date BETWEEN start_date AND end_date) AND MID(days, day, 1) = '1'
	UNION
	SELECT @feed_index, d.date, service_index FROM calendar_dates cd, dates d WHERE feed_index = @feed_index AND cd.date = d.date AND cd.exception_type = 1;
DELETE sid FROM service_indexes_per_date sid INNER JOIN calendar_dates cd ON sid.feed_index = @feed_index AND cd.feed_index = @feed_index AND sid.service_index = cd.service_index AND sid.date = cd.date WHERE exception_type = 2;

SELECT MIN(date), MAX(date) INTO @feed_start_date, @feed_end_date FROM service_indexes_per_date WHERE feed_index = @feed_index;
UPDATE feeds SET feed_start_date = @feed_start_date, feed_end_date = @feed_end_date WHERE feed_index = @feed_index;
SELECT LPAD(feed_index, 10, ' ') AS feed_index, feed_start_date, feed_end_date, feed_name FROM feeds WHERE feed_index = @feed_index;

DROP TABLE tmp_agency, tmp_calendar, tmp_calendar_dates, tmp_routes, tmp_shapes, tmp_stop_times, tmp_stops, tmp_trips;

