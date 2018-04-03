CREATE TABLE IF NOT EXISTS Confirmations (
  confirmation_id INTEGER PRIMARY KEY,
  token TEXT NOT NULL,  
  email TEXT NOT NULL,
  package TEXT NOT NULL,
  timestamp TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS Users (
  user_id INTEGER PRIMARY KEY,
  email TEXT NOT NULL,
  unsub_token TEXT NOT NULL,
  timestamp TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS Alerts (
  alert_id INTEGER PRIMARY KEY,
  email TEXT NOT NULL,
  package TEXT NOT NULL,
  timestamp TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS PackageInfo (
  Package TEXT NOT NULL,
  Version TEXT NOT NULL
);
