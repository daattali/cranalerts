# CRANalerts

A service by [AttaliTech Ltd](https://attalitech.com) that lets you subscribe to updates to CRAN packages. Available at [CRANalerts.com](https://cranalerts.com/).

**If you find CRANalerts useful, please consider supporting it\!**

<p align="center">

<a style="display: inline-block;" href="https://paypal.me/daattali">
<img height="35" src="https://camo.githubusercontent.com/0e9e5cac101f7093336b4589c380ab5dcfdcbab0/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f74776f6c66736f6e2f70617970616c2d6769746875622d627574746f6e40312e302e302f646973742f627574746f6e2e737667" />
</a>
<a style="display: inline-block; margin-left: 10px;" href="https://github.com/sponsors/daattali">
<img height="35" src="https://i.imgur.com/034B8vq.png" /> </a>

</p>

### Technical setup details (local testing):

1. Run the `dev_init()` function found in the `scripts/dev_init.R` file:

    ```
    source("scripts/dev_init.R"); dev_init()
    ```

    A SQLite database `cranalerts.sqlite3` will be created.

2. If you have an SMTP server settings and would like to send emails, create a `config.yml` file in the root directory using the template of [`config.yml.sample`](./config.yml.sample), and edit all the values to match your settings.

### Technical setup details (production):

1. Create a SQLite database

    ```
    sqlite3 cranalerts.sqlite3 < init_cranalerts_db.sql
    ```
    
    Make sure to make the database file readable/writeable to the owner and group, so that both shiny and cronjobs will be able to write to it

2. Create a `config.yml` file in the root directory using the template of [`config.yml.sample`](./config.yml.sample), and edit all the values to match your email server settings.

3. Install `rJava` package (for email sending using `mailr`) and configure it. I was having a lot of trouble getting it to work, it seems that it was not working with Java 11. I had to follow these steps after already having Java 11 installed:

   - Run `apt install openjdk-8-jdk openjdk-8-jre`
   - Run `update-alternatives --config java` (since I already had java 11 and I wanted to downgrade)
   - Add java paths to environment `/etc/environment`: `JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64` and `JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre`
   - (Reboot machine so that the envvars get loaded or set the environment variables temporarily)
   - Make sure the path is set and java 8 is used: `printenv JAVA_HOME` and `java -version`
   - Run `R CMD javareconf` to set up java with R
   - Now installing `rJava` pacakge should work, and sending emails with `mailR` should work

4. Set up a cron job (`crontab -e`) to run the update script (the following results in the script running daily at 13:00)

    ```
    0 13 * * * /srv/shiny-server/cranalerts/scripts/run_cranalerts_script.sh > /srv/shiny-server/cranalerts/scripts/run_cranalerts_script.log 2>&1
    ```
