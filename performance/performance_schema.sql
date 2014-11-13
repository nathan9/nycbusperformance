# analysis_schema.sql

DROP TABLE IF EXISTS events;
CREATE TABLE events (
        service_date date NOT NULL,
        trip_index int NOT NULL,
        vehicle_id smallint(4) ZEROFILL NOT NULL,
        stop_id int(6) NOT NULL,
        est_dep_utc datetime,
        dep_accuracy int,
        sched_dep_utc datetime,
	sched_dep_date date,
	sched_dep_hour tinyint(2),
	route_id varchar(255) NOT NULL,
	direction_id bool NOT NULL,
        PRIMARY KEY (service_date, trip_index, vehicle_id, stop_id),
	INDEX (sched_dep_date, sched_dep_hour, route_id, direction_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS adherence;
CREATE TABLE adherence (
        date date NOT NULL,
	hour tinyint(2) ZEROFILL NOT NULL,
        route_id varchar(255) NOT NULL,
        direction_id tinyint(1) NOT NULL,
        stop_id int(6) NOT NULL,
        early tinyint NOT NULL,
        on_time tinyint NOT NULL,
        late tinyint NOT NULL,
	PRIMARY KEY (date, hour, route_id, direction_id, stop_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

