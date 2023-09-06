#!/bin/bash

# Define the path to the external file
config_file="config.env"

# Define the logging files
ambience_log="$(date +%Y%m%d)-installation.log"

# Check if the file exists
if [[ ! -f "$config_file" ]]; then
  echo "Error: $config_file not found!"
  exit 1
fi

source "$config_file"
username=$(whoami)

handle_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error: $1" >> $ambience_log
  exit 1
}


# Check if path exist
if [ -d "java17" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Local folder 'java17' exists. Proceed to export to ${pathofJava}" | tee -a $ambience_log
  sudo mkdir -p ${pathofJava} || handle_error "Failed to create path ${pathofJava}"
  sudo cp -pr java17/* ${pathofJava}  || handle_error "Failed to create copy java binaries to ${pathofJava}"
  sudo chown $username:$username ${pathofJava}
  sudo rm -rf ./java17
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing Java..." | tee -a $ambience_log
  sudo ln -s ${pathofJava}/*/bin/* /usr/local/bin || handle_error "Failed to create symbolic link ${pathofJava}/java in /usr/local/bin"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hostname: $(hostname) IP Address: $(hostname -i)" | tee -a $ambience_log
  echo ${pathofJava} | tee -a $ambience_log
  ls -la ${pathofJava} | tee -a $ambience_log
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Testing Java version" | tee -a $ambience_log
  java --version | tee -a $ambience_log || handle_error "Failed to create symbolic link ${pathofJava}/java in /usr/local/bin" 
else
  echo "Folder 'java17' does not exist." | tee -a $ambience_log
fi

if [ -d "mongo" ]; then
  echo ""	
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Local folder 'mongo' exists. Proceed to export to ${pathofDBServer}" | tee -a $ambience_log
  sudo mkdir -p ${pathofDBServer} || handle_error "Failed to create path ${pathofDBServer}"
  sudo cp -p -rf ./mongo/* ${pathofDBServer} || handle_error "Failed to copy mongod binaries to ${pathofDBServer}"
  sudo mkdir -p ${pathofDBServerLib} || handle_error "Failed to create storage: ${pathofDBServerLib}"
  sudo mkdir -p $(dirname "${pathofDBServerLog}") || handle_error "Failed to create system log: ${pathofDBServerLog}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing MongoDB..." | tee -a $ambience_log
  sudo chown $username:$username -R ${pathofDBServer}
  sudo cp ${pathofDBServer}/*/bin/* /usr/local/bin || handle_error "Failed to copy mongod binaries to /usr/local/bin"
  sudo cp mongod.service /usr/lib/systemd/system || handle_error "Failed to create mongod.service"
  sudo cp -p ./mongod.conf ${pathofDBServer} || handle_error "Failed to copy mongod.conf to ${pathofDBServer}"
  rm ./mongod.conf
  sudo rm -rf ./mongo
  rm ./mongod.service
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hostname: $(hostname) IP Address: $(hostname -i)" | tee -a $ambience_log
  echo ${pathofDBServer} | tee -a $ambience_log
  ls -la ${pathofDBServer} | tee -a $ambience_log
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Testing mongod version" | tee -a $ambience_log
  mongod --version | tee -a $ambience_log || handle_error "Failed to copy mongod to /usr/local/bin"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] MongoDB installed as a service."
  sudo systemctl start mongod.service || handle_error "Failed to start mongod.service"
  sudo systemctl enable mongod.service > /dev/null 2>&1
  sleep 3
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hostname: $(hostname) IP Address: $(hostname -i)"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Verifying MongoDB Service" >> $ambience_log
  systemctl list-units --type=service --state=running  | grep mongo >> $ambience_log
  systemctl status mongod.service --no-pager
else
  echo "Folder 'mongo' does not exist." | tee -a $ambience_log
fi

if [ -d "amb" ]; then
  echo ""	
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Local folder 'amb' exists. Proceed to export to ${pathofAPPServer}" | tee -a $ambience_log
  sudo mkdir -p ${pathofAPPServer} || handle_error "Failed to create path ${pathofAPPServer}"
  sudo cp -p -rf ./amb/* ${pathofAPPServer} || handle_error "Failed to copy Ambience to ${pathofAPPServer}"
  sudo chown $username:$username ${pathofAPPServer}
  sudo rm -rf ./amb
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing Ambience as a service..." | tee -a $ambience_log
  sudo cp elx-ambience.service /usr/lib/systemd/system || handle_error "Failed to create elx-ambience.service"
  rm ./elx-ambience.service
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hostname: $(hostname) IP Address: $(hostname -i)" | tee -a $ambience_log
  echo ${pathofAPPServer} | tee -a $ambience_log
  ls -la ${pathofAPPServer} | tee -a $ambience_log
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Testing Ambience202x version" | tee -a $ambience_log
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(cat ${pathofAPPServer}/*/VERSION)" | tee -a $ambience_log
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ambience installed as a service."
  sudo systemctl start elx-ambience.service || handle_error "Failed to start elx-ambience"
  sudo systemctl enable elx-ambience.service > /dev/null 2>&1
  sleep 3
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hostname: $(hostname) IP Address: $(hostname -i)"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Verifying Ambience Service" >> $ambience_log
  systemctl list-units --type=service --state=running  | grep ambience >> $ambience_log
  systemctl status elx-ambience.service --no-pager
  echo ""
  echo "Connecting to the browser..." | tee -a $ambience_log
  sleep 5
  curl -i localhost:${externalPort} | tee -a $ambience_log || handle_error "Failed to connect to browser" 
else
  echo "Folder 'amb' does not exist." | tee -a $ambience_log
fi

