REM MS4W Shell is running ogr2ogr 2.1.0 with pg driver
REM OSGeo4Win Shell (1) is running ogr2ogr 2.1.2 with pg driver
REM OSGeo4Win Shell (2) is running ogr2ogr 2.1.3 with pg driver
REM See https://github.com/BerryDaniel/OLASFG-OpenStreetMap
createdb -U postgres osm
psql -U postgres -d osm -c "CREATE EXTENSION postgis;"
psql -U postgres -d osm -a -f sql/cleanGeometry.sql

REM POINTS
ogr2ogr --config OSM_CONFIG_FILE osmconf.ini --config OGR_INTERLEAVED_READING YES --config OSM_MAX_TMPFILE_SIZE 8000 -f PostgreSQL "PG:host=localhost user=postgres dbname=osm password=!ArcBark2" osm/south-carolina-latest.osm.pbf points --debug on
psql -U postgres -d osm -a -f sql/osm_point_tables.sql
REM psql -U postgres -d osm -a -c "DROP TABLE points;"

REM LINES
ogr2ogr --config OSM_CONFIG_FILE osmconf.ini --config OGR_INTERLEAVED_READING YES --config OSM_MAX_TMPFILE_SIZE 8000 -f PostgreSQL "PG:host=localhost user=postgres dbname=osm password=!ArcBark2" osm/south-carolina-latest.osm.pbf lines --debug on
psql -U postgres -d osm -a -f sql/osm_line_tables.sql
REM psql -U postgres -d osm -a -c "DROP TABLE lines;"

REM POLY
ogr2ogr --config OSM_CONFIG_FILE osmconf.ini --config OGR_INTERLEAVED_READING YES --config OSM_MAX_TMPFILE_SIZE 8000 -f PostgreSQL "PG:host=localhost user=postgres dbname=osm password=!ArcBark2" osm/south-carolina-latest.osm.pbf multipolygons --debug on
psql -U postgres -d osm -a -f sql/osm_polygon_tables.sql
REM psql -U postgres -d osm -a -c "DROP TABLE multipolygons;"

REM https://github.com/openstreetmap/mapnik-stylesheets/tree/master/symbols
REM https://github.com/boundlessgeo/suite-data/blob/master/openstreetmap/workspaces/osm/styles
REM TODO: Add -watch to PUT sld each time file changes
curl -v -u admin:geoserver -XPOST -H "Content-type:text/xml" -d "<featureType><name>osm_transportation</name></featureType>" http://localhost:8080/geoserver/rest/workspaces/osm/datastores/openstreetmap/featuretypes?recalculate=nativebbox,latlonbbox
curl -v -u admin:geoserver -XPOST -H "Content-type:text/xml" -d "<style><name>transportation</name><filename>transportation.sld</filename></style>" http://localhost:8080/geoserver/rest/workspaces/osm/styles
curl -v -u admin:geoserver -XPUT -H "Content-type:application/vnd.ogc.sld+xml" -d @sld/transportation.sld http://localhost:8080/geoserver/rest/workspaces/osm/styles/transportation
curl -v -u admin:geoserver -XPUT -H "Content-type:text/xml" -d "<layer><enabled>true</enabled><defaultStyle><name>transportation</name><workspace>osm</workspace></defaultStyle></layer>" http://localhost:8080/geoserver/rest/layers/osm:osm_transportation

