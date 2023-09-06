# Ambience2023-MongoDB-Java17-Setup
**What was your motivation?**
This bash script was created to seamlessly integrate ElixirTech Pte Ltd's Ambience2023 with MongoDB Community or Enterprise edition with a Linux OS.

This applies to both Ubuntu or RHEL.

**Why did you build this project?**
I was tasked to integrate Ambience2023 with MongoDB in Dev, SIT, UAT and PROD. I needed something to quickly set it up and run. This is where this script is born.

**What problem does it solve?**
ElixirTech Pte Ltd's Ambience2023 requires Java17 and MongoDB to start. Importing the binaries for java and mongod is easy but exporting them to /usr/local/bin is pretty manual. This script will export Java17 and MongoDB's binaries to /usr/local/bin and create the service file needed to start Ambience2023 and MongoDB as a service.

**What did you learn?**
When it comes to JDK, I choose to use a symbolic link to connect to /usr/local/bin instead of creating two symbolic link to connect /usr/bin with /etc/alternatives.
I also realized you can use netstat -tuln to determine if the ports for Ambience2023 and MongoDB are up and running. This is much faster approach to determine if the service is up and running then using systemctl status.

**What makes your project stand out?**
It will usually take around 30 mins for you to setup Ambience2023, Java17 and MongoDB for one VM. This includes creating mongod.conf, mongod.service and elx-ambience.service, not to forget the storage folder for mongod and system log.

**How to Install and Run the Project?**
Requirements:
1. Run uname -a to determine the architecture of the VM. (e.g. It could be arm64 or x86_64)
2. Run cat /etc/os-release to determine the OS version. (e.g. It could be ubuntu or RHEL)
3. Ensure you have the zip command installed in your Linux
4. Once you determine the above two. Proceed to download the following:
   a. OpenJDK 17 - https://www.openlogic.com/openjdk-downloads
   b. MongoDB - https://www.openlogic.com/openjdk-downloads
   c. Ambience2023 - Get a trial version from sales@elixirtech.com
   
There are three files in total.
1. extract.sh
2. start.sh
3. config.env
4. YYYYMMDD-installation.log

**Step 1: Run extract.sh To Extract Archive Files**

Run ./extract.sh and you'll get this:
![image](https://github.com/davidaw78/Ambience2023-MongoDB-Java17-Setup/assets/89636227/39dc9bd6-705b-4bb9-ad3f-88b37473fa63)
