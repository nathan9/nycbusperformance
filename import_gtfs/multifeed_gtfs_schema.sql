# multifeed_gtfs_schema.sql

DROP TABLE IF EXISTS feeds; 
CREATE TABLE feeds (
	feed_index smallint AUTO_INCREMENT PRIMARY KEY,
	feed_start_date date NOT NULL,
	feed_end_date date NOT NULL,
	feed_name varchar(255) NOT NULL,
	INDEX (feed_start_date, feed_end_date)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS agency;
CREATE TABLE agency (
	feed_index smallint NOT NULL,
	agency_index int AUTO_INCREMENT PRIMARY KEY,
	agency_id varchar(255) NOT NULL,
	agency_name varchar(255) NOT NULL,
	agency_url varchar(255) NOT NULL,
	agency_timezone varchar(255) NOT NULL,
	agency_lang varchar(255) NOT NULL,
	UNIQUE (feed_index, agency_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS calendar;
CREATE TABLE calendar (
	feed_index smallint NOT NULL,
	service_index int AUTO_INCREMENT PRIMARY KEY,
	service_id varchar(255) NOT NULL,
	days char(7) NOT NULL,
	start_date date NOT NULL,
	end_date date NOT NULL,
	UNIQUE(feed_index, service_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS calendar_dates;
CREATE TABLE calendar_dates (
	feed_index smallint NOT NULL,
	service_index int NOT NULL,
	service_id varchar(255) NOT NULL,
	date date NOT NULL,
	exception_type tinyint NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS routes;
CREATE TABLE routes (
	feed_index smallint NOT NULL,
	route_index int AUTO_INCREMENT PRIMARY KEY,
	route_id varchar(255) NOT NULL,
	agency_index int NOT NULL,
	route_short_name varchar(255) NOT NULL,
	route_long_name varchar(255) NOT NULL,
	route_desc varchar(255) NOT NULL,
	route_type tinyint NOT NULL,
	route_url varchar(255) NOT NULL,
	route_color varchar(255) NOT NULL,
	route_text_color varchar(255) NOT NULL,
	UNIQUE (feed_index, route_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS shapes;
CREATE TABLE shapes (
	feed_index smallint NOT NULL,
	shape_index int NOT NULL,
	shape_id varchar(255) NOT NULL,
	shape_pt_lat decimal(8, 6) NOT NULL,
	shape_pt_lon decimal(9, 6) NOT NULL,
	shape_pt_sequence int NOT NULL,
	PRIMARY KEY (shape_index, shape_pt_sequence),
	INDEX (feed_index, shape_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS stop_times;
CREATE TABLE stop_times (
	trip_index int NOT NULL,
	arrival_time time,
	departure_time time,
	stop_id int(6) NOT NULL,
	stop_sequence int NOT NULL,
	pickup_type tinyint NOT NULL,
	drop_off_type tinyint NOT NULL,
	PRIMARY KEY (trip_index, stop_sequence),
	INDEX (trip_index, stop_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS stops;
CREATE TABLE stops (
	feed_index smallint NOT NULL,
	stop_index int AUTO_INCREMENT PRIMARY KEY,
	stop_id int(6) NOT NULL,
	stop_name varchar(255) NOT NULL,
	stop_desc varchar(255) NOT NULL,
	stop_lat decimal(8, 6) NOT NULL,
	stop_lon decimal(9, 6) NOT NULL,
	UNIQUE (feed_index, stop_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS trips;
CREATE TABLE trips (
	feed_index smallint NOT NULL,
	trip_index int AUTO_INCREMENT PRIMARY KEY,
	route_index int NOT NULL,
	service_index int NOT NULL,
	trip_id varchar(255) NOT NULL,
	trip_headsign varchar(255) NOT NULL,
	direction_id tinyint NOT NULL,
	shape_index int NOT NULL,
	UNIQUE (feed_index, trip_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS service_indexes_per_date;
CREATE TABLE service_indexes_per_date (
	feed_index smallint NOT NULL,
	date date NOT NULL,
	service_index int NOT NULL,
	INDEX (feed_index, date)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

