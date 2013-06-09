#!/usr/bin/env ruby
require 'sqlite3'

DB_NAME = 'wc.db'
db = SQLite3::Database.new(DB_NAME)

db.execute <<SQL

  CREATE TABLE IF NOT EXISTS word_count (
    id integer primary key,
    path string,
    words integer,
    timestamp date DEFAULT CURRENT_DATE,
    UNIQUE (path, timestamp)
  );

SQL

Dir.glob('**') do | file |
  path = File.absolute_path(file)
  next if path == File.absolute_path(DB_NAME) || path == File.absolute_path(__FILE__)
  words = `wc -w #{file}`.split(' ')[0]
  timestamp = Time.now.strftime('%F')

  db.execute <<SQL

    INSERT OR IGNORE INTO word_count (path, words, timestamp) 
    VALUES ('#{path}', '#{words}', '#{timestamp}');

    UPDATE word_count
    SET words = '#{words}'
    WHERE path = '#{path}'
    AND timestamp = '#{timestamp}'
SQL
  
end

