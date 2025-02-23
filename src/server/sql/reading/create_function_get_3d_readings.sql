/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 */

/*
    The meter_3d_readings_unit function works similarly to the meter_line_readings_unit but it returns
    a table of hourly readings. The parameters are meter_id (ID of meter requested),
    graphic_unit_id (ID of the unit being requested), start_stamp, end_stamp (date ranges requested e.g. 2023-01-09)
*/
CREATE OR REPLACE FUNCTION meter_3d_readings_unit (
    meter_id INTEGER,
    graphic_unit_id INTEGER,
    start_stamp TIMESTAMP,
    end_stamp TIMESTAMP,
    sequence_number INTEGER
)
RETURNS TABLE(reading_rate FLOAT, start_timestamp TIMESTAMP, end_timestamp TIMESTAMP)
AS $$
DECLARE
    requested_range TSRANGE;
    unit_column INTEGER;
    requested_meter_id INTEGER;
    requested_sequence TEXT;
BEGIN

    -- unit_column holds the column index into the cik table. This is the unit that was requested for graphing.
    SELECT unit_index INTO unit_column FROM units WHERE id = graphic_unit_id;

    -- Get the range of days requested by calling shrink_tsrange_to_real_readings_by_day.
    requested_range := shrink_tsrange_to_real_readings_by_day(tsrange(start_stamp, end_stamp, '[]'));

    -- Holds the id of the meter being requested.
    requested_meter_id := meter_id;

    --Requested sequence
    requested_sequence := sequence_number::TEXT || ' hour';


    RETURN QUERY
		SELECT
            AVG(hourly_readings.reading_rate) AS reading_rate,
			gen.interval_start AS start_timestamp,
			gen.interval_start + requested_sequence::INTERVAL AS end_timestamp
		FROM (SELECT
			    hourly.reading_rate * c.slope + c.intercept AS reading_rate,
                lower(hourly.time_interval) AS start_timestamp,
			    upper(hourly.time_interval) AS end_timestamp
		        FROM (((hourly_readings_unit hourly
			    INNER JOIN meters m ON m.id = requested_meter_id)
			    INNER JOIN units u ON m.unit_id = u.id)
			    INNER JOIN cik c on c.row_index = u.unit_index AND c.column_index = unit_column)
			    WHERE requested_range @> time_interval AND hourly.meter_id = requested_meter_id
			    -- This ensures the data is sorted
			    ORDER BY start_timestamp ASC
            ) AS hourly_readings
            CROSS JOIN LATERAL generate_series(
			        date_trunc('hour', start_stamp),
			        date_trunc_up('hour', end_stamp) - requested_sequence::INTERVAL,
			        requested_sequence::INTERVAL
		    ) gen(interval_start)
            WHERE hourly_readings.start_timestamp BETWEEN gen.interval_start AND gen.interval_start + requested_sequence::INTERVAL AND hourly_readings.end_timestamp BETWEEN gen.interval_start AND gen.interval_start + requested_sequence::INTERVAL
            GROUP BY gen.interval_start 
            ORDER BY start_timestamp ASC;
            
END;
$$ LANGUAGE plpgsql;
