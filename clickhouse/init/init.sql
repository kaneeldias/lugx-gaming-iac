CREATE DATABASE IF NOT EXISTS web_analytics;

CREATE TABLE IF NOT EXISTS web_analytics.page_views (
    id UUID DEFAULT generateUUIDv4(),
    path String,
    ip_address String,
    timestamp DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id;

CREATE TABLE IF NOT EXISTS web_analytics.clicks (
    id UUID DEFAULT generateUUIDv4(),
    path String,
    element String,
    ip_address String,
    timestamp DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id;

CREATE TABLE IF NOT EXISTS web_analytics.page_times (
    id UUID DEFAULT generateUUIDv4(),
    path String,
    time_spent UInt32,
    ip_address String,
    timestamp DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id;
