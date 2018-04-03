# CRANalerts

A service by [AttaliTech Ltd](http://attalitech.com) that lets you subscribe to updates to CRAN packages.

Technical setup details:

1. Create database

    ```
    sqlite3 cranalerts.sqlite3 < init_cranalerts_db.sql
    ```
    
    Make sure to make the database file read/write to the owner and group

2. Install `rJava` package (for email sending using `mailr`) and configure it. Create `/etc/ld.so.conf.d/java.conf` file with the following content:

    ```
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server 
    ```
    
    Then run `sudo ldconfig`

3. Create a `config.yml` file in the root directory that will be used to store email server settings, with the following format:

    ```
    default:
      Smtp.Username: "username"
      Smtp.Password: "password"
      Smtp.Server: "server"
      Smtp.Port: "25"
      Smtp.From: "CRANalerts <email@email.com>"
      Smtp.ReplyTo: "CRANalerts <email@email.com>"
    ```

4. Set up a crontab to run the update script `crontab -e` (this makes it run at 13:00 daily)

    ```
    0 13 * * * /srv/shiny-server/cranalerts/scripts/run_cranalerts_script.sh > /srv/shiny-server/cranalerts/scripts/run_cranalerts_script.log 2>&1
    ```
