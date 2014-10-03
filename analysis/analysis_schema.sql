# analysis_schema.sql

DROP TABLE IF EXISTS events;
CREATE TABLE events (
        service_date date NOT NULL,
        trip_index int NOT NULL,
        vehicle_id smallint(4) ZEROFILL NOT NULL,
        stop_id int(6) NOT NULL,
        est_dep_time datetime,
        dep_accuracy int,
        sched_dep_time datetime,
        PRIMARY KEY (service_date, trip_index, vehicle_id, stop_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

