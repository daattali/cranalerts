# CRANalerts

A service by [AttaliTech Ltd](http://attalitech.com) that lets you subscribe to updates to CRAN packages.

Technical setup details:

1. Create database

    ```
    sqlite3 cranalerts.sqlite3 < init_cranalerts_db.sql
    ```
    
    Make sure to make the database file readable/writeable to the owner and group

2. Install `rJava` package (for email sending using `mailr`) and configure it. I was having a lot of trouble getting it to work, it seems that it was not working with Java 11. I had to follow these steps:

   - Run `apt install openjdk-8-jdk openjdk-8-jre`
   - Run `update-alternatives --config java` (since I already had java 11 and I wanted to downgrade)
   - Add java paths to environment `/etc/environment`: `JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64` and `JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre`
   - (Reboot machine to set the envvars or set the environment variables temporarily)
   - Make sure the path is set and java 8 is used: `printenv JAVA_HOME` and `java -version`
   - Run `R CMD javareconf` to set up java with R
   - Now installing `rJava` pacakge should work, and sending emails with `mailR` should work

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
