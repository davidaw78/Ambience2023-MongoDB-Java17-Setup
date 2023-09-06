#!/bin/bash

# Define the path to the external file
config_file="config.env"

# Define the logging files
ambience_log="$(date +%Y%m%d)-installation.log"
touch $ambience_log

# Check if the file exists
if [[ ! -f "$config_file" ]]; then
  echo "Error: $config_file not found!" | tee -a $ambience_log
  exit 1
fi

source "$config_file"

# Set default values if parameters are empty or unset
externalIPAddr="${externalIPAddr:-localhost}"
externalPort="${externalPort:-1740}"
pathofAPPServer="${pathofAPPServer:-/opt/amb}"
mongoDBIPAddr="${mongoDBIPAddr:-locahost}"
mongoDBPort="${mongoDBPort:-27017}"
mongoDBHost="${mongoDBHost:-"127.0.0.1"}"
pathofDBServer="${pathofDBServer:-/opt/mongo}"
pathofDBServerLog="${pathofDBServerLog:-/opt/mongo/log/mongodb/mongod.log}"
pathofDBServerLib="${pathofDBServerLib:-/opt/mongo/lib/mongo}"

# Use find to locate all files with extensions .zip, .tar, or .tgz in /home
files=$(find . -maxdepth 1 -name "*.zip" -o -name "*.tar*" -o -name "*.tgz" -type f)
file1=$(find . -name "start.sh" -type f)

username=$(whoami)
PATTERN='$USER'
ip_address=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1)

handle_error() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error: $1" >> $ambience_log
  exit 1
}

# Create amb folder
function createAMB() {
  mkdir ./amb && echo "amb created successful" || handle_error "Failed to create amb in current path."
  unzip "$1" -d amb && echo "$1 file extraction successful" || handle_error "Failed to create amb in current path."
  # sudo cp -p ./amb ${pathofAPPServer} && echo "amb move to ${pathofAPPServer}" || handle_error "Failed to copy amb to ${pathofAPPServer}"
  # rm -rf ./amb
  path_found=$(find . -name 'elx-stub.jar' -print -quit)
  path_audit=$(dirname $path_found)
  path_real=$(echo "$path_audit" | sed 's|^./||')
  filename=$(basename "$path_audit")
  createAmbienceFile $filename
  sed -i "s|$PATTERN|$username|g" $file1
  sed -i "s/external-host = ".*"/external-host = \"$ip_address\"/g; s/internal-host = ".*"/internal-host = "localhost"/g; s/mongodb = ".*"/mongodb = "localhost"/g" ./$path_real/etc/application.conf
}

function createJava() {
  mkdir ./java17 && echo "Folder java17 created successful" || handle_error "Failed to create java17 in current path."
  tar xvf "$1" -C java17 && echo "$1 file extraction successful" || handle_error "Failed to extract tar file."
  # sudo cp -p ./java17/* ${pathofJava} && echo "java17 move to ${pathofJava}" | tee -a error.log || handle_error "Failed to copy java17 to ${pathofJava}"
  # rm -rf ./java17
}

function createMongo() {
  mkdir ./mongo && echo "Folder mongo created successful" || handle_error "Failed to create mongo in current path."
  tar xvfz "$1" -C mongo && echo "$1 file extraction successful" || handle_error "Failed to extract tgz file."
  createMongodConf
  createMongodService
  # sudo cp -p ./mongo/* ${pathofDBServer} && echo "mongo/* move to ${pathofDBServer}" | tee -a error.log || handle_error "Failed to copy mongo/* to ${pathofDBServer}"
}

# Create the mongod.service file
function createMongodService() {
cat << EOF > ./mongod.service
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
Group=$USER
Environment="OPTIONS=-f ${pathofDBServer}/mongod.conf"
EnvironmentFile=-/etc/sysconfig/mongod
ExecStart=/usr/local/bin/mongod \$OPTIONS
ExecStartPre=/usr/bin/mkdir -p /var/run/mongodb
ExecStartPre=/usr/bin/chown $USER:$USER /var/run/mongodb
ExecStartPre=/usr/bin/chmod 0755 /var/run/mongodb
PermissionsStartOnly=true
PIDFile=/var/run/mongodb/mongod.pid
Type=fork

# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false
# Recommended limits for mongod as specified in
# https://docs.mongodb.com/manual/reference/ulimit/#recommended-ulimit-settings

[Install]
WantedBy=multi-user.target

EOF
echo "File mongod.service created with the provided content." || handle_error "Failed to create mongod.service."
# sudo mv mongod.service /usr/lib/systemd/system || handle_error "Failed to create mongod.service in /usr/lib/systemd/system."
}

# Create the mongod.conf file
function createMongodConf() {
cat << EOF > ./mongod.conf
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: ${pathofDBServerLog}

# Where and how to store data.
storage:
  dbPath: ${pathofDBServerLib}
  journal:
    enabled: true
#  engine:
#  wiredTiger:

# how the process runs
processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo

# network interfaces
net:
  port: 27017
  bindIp: ${mongoDBHost}  # Enter 0.0.0.0,:: to bind to all IPv4 and IPv6 addresses or, alternatively, use the net.bindIpAll setting.


security:
  authorization: disabled

#operationProfiling:

#replication:

#sharding:

## Enterprise-Only Options

#auditLog:

#snmp:

EOF

echo "Files mongod.conf created with the provided content." || handle_error "Failed to create mongod.conf."
# sudo mv mongod.conf ${pathofDBServer} || handle_error "Failed to create mongod.conf in ${pathofDBServer}."
}

# Create the elx-ambience.service file
function createAmbienceFile() {
mypath=$1

cat << EOF > ./elx-ambience.service
[Unit]
Description=Run Elx Ambience 2023 Server
After=network.target

[Service]
User=$USER
Group=$USER
WorkingDirectory=${pathofAPPServer}/$mypath/bin
ExecStart=/bin/bash ${pathofAPPServer}/$mypath/bin/run-server
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOF

echo "File elx-ambience.service created with the provided content." || handle_error "Failed to create elx-ambience.service."
# sudo mv elx-ambience.service ${pathofAPPServer} || handle_error "Failed to create elx-ambience.service in /usr/lib/systemd/system."
}

# Display the list of matching files in a table
if [ -n "$files" ]; then
  echo "The following files were found:"
  printf '%-5s %-30s\n' "#" "Filename"
  echo "----------------------------------------"
  echo "0     Install Using Internet"
  count=1
  for file in $files; do
    printf '%-5s %-30s\n' "$count" "$file"
    (( count++ ))
  done
else
  echo "No matching files were found." | tee -a $ambience_log
  exit 1
fi

# Prompt the user to choose a file to extract, or extract all files by default
read -p "Enter the number of the file to extract (e.g. 1), or press Enter to extract all files: " file_num
if [ -n "$file_num" ]; then
  if [ "$file_num" -ge 0 ] && [ "$file_num" -le "$count" ]; then  # Change >= 1 to >= 0
    if [ "$file_num" -eq 0 ]; then
      echo "Installing using the Internet..."
      # Add your internet installation code here
    else
      # Extract the chosen file based on its extension
      chosen_file=$(echo "$files" | sed -n "${file_num}p")
      case "$chosen_file" in
        *.zip)
          createAMB $chosen_file
          ;;
        *.tar*)
          createJava $chosen_file
          ;;
        *.tgz)
          createMongo $chosen_file
          ;;
        *)
          echo "Unknown file type" | tee -a $ambience_log
          exit 1
          ;;
      esac
    fi
  else
    echo "Invalid file number" | tee -a $ambience_log
    exit 1
  fi
else
  # Extract all files based on their extension
  for file in $files; do
    case "$file" in
      *.zip)
        createAMB $file
        ;;
      *.tar*)
        createJava $file
        ;;
      *.tgz)
        createMongo $file
        ;;
    esac
  done
fi

