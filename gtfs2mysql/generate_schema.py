#!/usr/bin/python

# Generates a MySQL schema named "schema.sql" based on the first line (assumed to be a header) of each file matching "tmp_*.txt" in the current directory.  Each text file becomes a database table and each comma-separated value in its header becomes a varchar column in that table.

from glob import glob
import csv

schema = open('schema.sql', 'w')
filenames = glob('tmp_*.txt')
for filename in filenames:
        table = filename[:-4]
        fields = []
        csv_file = open(filename, 'r')
        reader = csv.reader(csv_file, delimiter=',', quotechar='"')
        header = reader.next()
        csv_file.close()
        for field in header:
                fields += ['\t' + field.strip() + ' varchar(255) NOT NULL']
        schema.write('DROP TABLE IF EXISTS ' + table + ';\nCREATE TABLE ' + table + ' (\n')
        schema.write(',\n'.join(fields) + '\n')
        schema.write(') ENGINE=MyISAM DEFAULT CHARSET=latin1;\n\n')
schema.close()

