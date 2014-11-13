# NYC Bus Performance

The NYC Bus Performance project is intended to allow the analysis of New York City bus behavior and performance, such as determining [schedule adherence](http://nathan9.github.io/nycbusperformance/) or headway variance, and comparison with other data (e.g., weather, traffic, SES).

## Applications

- Reporting bus performance using tables, rankings, and visualizations
- Allowing journey planners to take service reliability into consideration when suggesting routes
- Backtesting algorithms that predict bus arrival times
- Generating time-lapse visualizations of historical bus movements to identify bottlenecks and illustrate "bus bunching"
- Checking alibis or excusing lateness
- Anything else you can think of!

## NYC Bus Archive

The project relies on data from the NYC Bus Archive, which is a compilation of MTA Bus schedule, position, and situation (service changes) data. The great bulk of the archive is made up of the bus positions data, captured from [MTA Bus Time's SIRI API](http://bustime.mta.info/wiki/Developers/Index) at approximately 30-60 second intervals - fields include data timestamp, vehicle ID, latitude, longitude, bearing, trip ID, next stop ID, and distance from stop. The archive also includes a collection of historical GTFS feeds and situation records. The archive is currently stored in an [Amazon Web Services (AWS) S3](http://aws.amazon.com/s3/) bucket named "nycbusarchive". Resultant performance data are available to download from an AWS S3 bucket named "nycbusperformance". To prevent me from incurring bandwidth charges, access to the buckets requires an AWS account - [offers or suggestions](mailto:nathan9@gmail.com) of alternative hosting options are welcome.

## Technical

The project uses a series of [bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) scripts and [MySQL](http://www.mysql.com/products/community/) statements to manipulate the data. It is currently able to infer actual departure times and report schedule adherence. The next step would be to determine headway variance. However, this cannot be done safely yet as the MTA Bus API has poor latency (30+ seconds) during rush hour, which can result in substantial gaps in the data, meaning some departures aren't inferred. This could be remedied by using the schedule to fill in missing departures, although this method is complicated by the fact that MTA Bus Time sometimes has a bus flip-flop between different trip IDs.

To find schedule adherence, the following steps should be taken:

1. Ensure MySQL and bash are installed on your system
2. Run import_gtfs/setup.sh DB_NAME
3. Download GTFS files from the "nycbusarchive" bucket
4. Run import_gtfs/gtfs2mysql.sh DB_NAME GTFS_PATH
5. Run import_archive/setup.sh DB_NAME
6. Download positions data from the "nycbusarchive" bucket
7. Run import_archive/import_archive.sh DB_NAME ARCHIVE_PATH
8. Run performance/setup.sh DB_NAME
9. Run performance/add_events.sh DB_NAME START_DATE END_DATE
10. Run the SQL statements in performance/adherence.sql for a (small) date range

Given the sizes of the data involved, some of these steps may take a few minutes. Eventually, I may rewrite the whole process in C.

I'm not sure if there's an industry standard way of determining transit performance from this type of source data. For example, if we can infer that a departure occurred at some point in a given time range and the beginning of the range is "on time" but the end of the range is "late", should we consider the departure to have been "on time", "late", or "unknown"? Currently, the midpoint is used (as long as the accuracy is better than 60 seconds). Also, should departure times or arrival times be used, or both? What's a good way of reporting headway variance that can be easily understood by passengers? If you can answer any of these questions, [please let me know](mailto:nathan9@gmail.com).

## Legal

This project is not maintained or endorsed by the Metropolitan Transportation Authority (MTA). The performance and archive data are not guaranteed to be accurate, complete, or timely.

This project is published under the MIT License.

## Contact

The project is maintained by Nathan Johnson. Please direct questions, comments, suggestions, and contributions to [nathan9@gmail.com](mailto:nathan9@gmail.com).
