#!/bin/bash
find_python(){
  if ! command -v python3 >/dev/null 2>&1; then
    print_yellow "Python 3 not found! Installing python3."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv
  fi

  if command -v python3 >/dev/null 2>&1; then
    python=$(command -v python3)
    pip_pkg="python3-pip"
    pip_run='pip3'
    print_green "+ Found: $python"
  else
    print_yellow "Python 3 installation failed!\n Exiting\n"
    exit
  fi
}

printm(){
  length=$(expr length "$1")
  length=$(($length + 4))
  printf "\n"
  printf ":: $1 \n\n"
}

print_green(){
  tput setaf 2; echo "$1"
  tput sgr 0
}

print_yellow(){
  tput setaf 3; printf "$1"
  tput sgr 0
}

# Escape special characters for sed replacement
escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

check_and_install_pip(){
  pip_ver=$(${python} -m pip --version 2>&1);
  if [[ "$pip_ver" == *"No"* ]]; then
    echo "- Pip is not installed, installing it."
    sudo apt-get install -y $pip_pkg
  else
    print_green "+ Found: $pip_pkg"
  fi
}

create_venv(){
  printm "Creating virtual environment"
  # Check if python3-venv is installed
  if ! dpkg -l | grep -q python3-venv; then
    echo "python3-venv is not installed. Installing..."
    sudo apt-get install -y python3-venv
    else
    print_green "+ Found: python3-venv"
  fi

  # Create a virtual environment
  ${python} -m venv rpi_mon_env
  print_green "+ Virtual environment created"

  # Activate the virtual environment
  source rpi_mon_env/bin/activate
  python=$(command -v python3)
  print_green "+ Activated virtual environment"
}

install_requirements(){
  printm "Installing requirements"
  $pip_run install -r requirements.txt
  # Deactivate the virtual environment
  print_green "+ Requirements installed"
  print_green "+ Deactivating virtual environment"
  deactivate
}

mqtt_configuration(){
  printm "MQTT settings"
  
  printf "Enter mqtt_host: "
  read HOST
  HOST_ESC=$(escape_sed "$HOST")
  sed -i "s|ip address or host|${HOST_ESC}|" src/config.py

  printf "Enter mqtt_user: "
  read USER
  USER_ESC=$(escape_sed "$USER")
  sed -i "s|username|${USER_ESC}|" src/config.py

  printf "Enter mqtt_password: "
  read PASS
  PASS_ESC=$(escape_sed "$PASS")
  sed -i "s|\"password|\"${PASS_ESC}|" src/config.py

  printf "Enter mqtt_port (default is 1883): "
  read PORT
  if [ -z "$PORT" ]; then
    PORT=1883
  fi
  sed -i "s|1883|${PORT}|" src/config.py

  printf "Enter mqtt_topic_prefix (default is rpi-MQTT-monitor-v2): "
  read TOPIC
  if [ -z "$TOPIC" ]; then
    TOPIC=rpi-MQTT-monitor-v2
  fi
  TOPIC_ESC=$(escape_sed "$TOPIC")
  sed -i "s|rpi-MQTT-monitor-v2|${TOPIC_ESC}|" src/config.py

  printf "Enter mqtt_uns_structure (default is empty): "
  read UNS
  if [[ -n "$UNS" && ! "$UNS" =~ /$ ]]; then
    UNS="${UNS}/"
  fi
  UNS_ESC=$(escape_sed "$UNS")
  sed -i "s|mqtt_uns_structure = .*|mqtt_uns_structure = '${UNS_ESC}'|" src/config.py
  
  printf "Do you need to control your monitors? (default is No): "
  read CONTROL
  if [[ "$CONTROL" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sed -i "s/display_control = False/display_control = True/g" src/config.py
  fi
  finish_message="MQTT broker"
}

hass_api_configuration(){
    printf "Enter Home Assistant API URL (default is http://localhost:8123): "
    read HA_URL
    if [ -z "$HA_URL" ]; then
      HA_URL="http://localhost:8123"
    fi
    HA_URL_ESC=$(escape_sed "$HA_URL")
    sed -i "s|your_hass_host|${HA_URL_ESC}|" src/config.py

    printf "Enter Home Assistant API Token: "
    read HA_TOKEN
    HA_TOKEN_ESC=$(escape_sed "$HA_TOKEN")
    sed -i "s|your_hass_token|${HA_TOKEN_ESC}|" src/config.py
    hass_api=" --hass_api"
    finish_message="Home Assistant API"
}

update_config(){
  if [ -f src/config.py ]; then
    read -p "src/config.py already exists Do you want to remove it? (y/n) " yn
    case $yn in
        [Yy]* ) echo "replacing config file";;
        [Nn]* ) return;;
        * ) echo "Please answer y for yes or n for no.";;
    esac
  fi

  print_green "+ Copy config.py.example to config.py"
  cp src/config.py.example src/config.py

  user=$(whoami)
  user_ESC=$(escape_sed "$user")
  sed -i "s|os_user_to_be_replaced|${user_ESC}|" src/config.py

  echo "Do you want to use Home Assistant API or MQTT?"
  echo "1) Home Assistant API"
  echo "2) MQTT (default)"
  read -p "Enter your choice [1 or 2]: " choice

  # Run the appropriate configuration function based on the user's choice
  case $choice in
      1)
          hass_api_configuration
          ;;
      2 | "")
          mqtt_configuration
          ;;
      *)
          echo "Invalid choice. Defaulting to MQTT configuration."
          mqtt_configuration
          ;;
  esac


  print_green  "+ config.py is updated with provided settings"

  # Get the local version
  local_version=$(git describe --tags)
  # Update the version in config.py
  sed -i "s/version = .*/version = '${local_version}'/" src/config.py

}

set_cron(){
  printm "Setting Cronjob"
  cwd=$(pwd)
  crontab -l > tempcron
  if grep -q rpi-cpu2mqtt.py tempcron; then
    cronfound=$(grep rpi-cpu2mqtt.py tempcron)
    print_yellow " There is already a cronjob running rpi-cpu2mqtt.py - skipping cronjob creation.\n"
    print_yellow " If you want the cronjob to be automatically created remove the line below from your\n cronjobs list and run the installer again.\n\n"
    echo " ${cronfound}"
  else
    printf "How often do you want the script to run in minutes? (default is 2): "
    read MIN
    if [ -z "$MIN" ]; then
      MIN=2
    fi
    echo "Adding the line below to your crontab"
    echo "*/${MIN} * * * * cd ${cwd}; ${python} ${cwd}/src/rpi-cpu2mqtt.py${hass_api}"
    echo "*/${MIN} * * * * cd ${cwd}; ${python} ${cwd}/src/rpi-cpu2mqtt.py${hass_api}" >> tempcron
    crontab tempcron
  fi
  rm tempcron
}

set_service(){
  printm "Setting systemd service"

  if [ -f /etc/systemd/system/rpi-mqtt-monitor-v2.service ]; then
    read -p "Service file already exists. Do you want to remove it? (y/n) " yn
    case $yn in
        [Yy]* ) sudo rm /etc/systemd/system/rpi-mqtt-monitor-v2.service;;
        [Nn]* ) return;;
        * ) echo "Please answer y for yes or n for no.";;
    esac
  fi
  printf "How often do you want the script to run in seconds? (default is 120): "
  read MIN
  if [ -z "$MIN" ]; then
    MIN=120
  fi
  sed -i "s/120/${MIN}/" src/config.py
  cwd=$(pwd)
  user=$(whoami)
  exec_start="${python} ${cwd}/src/rpi-cpu2mqtt.py --service${hass_api}"
  print_green "+ Copy rpi-mqtt-monitor-v2.service to /etc/systemd/system/"
  sudo cp ${cwd}/rpi-mqtt-monitor-v2.service /etc/systemd/system/
  sudo sed -i "s|WorkingDirectory=.*|WorkingDirectory=${cwd}|" /etc/systemd/system/rpi-mqtt-monitor-v2.service
  sudo sed -i "s|User=YOUR_USER|User=root|" /etc/systemd/system/rpi-mqtt-monitor-v2.service
  sudo sed -i "s|ExecStart=.*|ExecStart=${exec_start}|" /etc/systemd/system/rpi-mqtt-monitor-v2.service
  home_dir=$(eval echo ~$user)
  sudo sed -i "s|Environment=\"HOME=/home/username\"|Environment=\"HOME=${home_dir}\"|" /etc/systemd/system/rpi-mqtt-monitor-v2.service
  sudo systemctl daemon-reload
  sudo systemctl enable rpi-mqtt-monitor-v2.service
  sudo systemctl start rpi-mqtt-monitor-v2.service
  sudo service rpi-mqtt-monitor-v2 restart
  print_green "+ Service is enabled and started"
  git config --global --add safe.directory ${cwd}
}

create_shortcut(){
  printm "Creating shortcut rpi-mqtt-monitor-v2"
  cwd=$(pwd)

  # Ensure /usr/local/bin exists
  if [ ! -d "/usr/local/bin" ]; then
    sudo mkdir -p /usr/local/bin
    print_green "/usr/local/bin created."
  fi

  echo "${python} ${cwd}/src/rpi-cpu2mqtt.py \$@" > rpi-mqtt-monitor-v2
  sudo mv rpi-mqtt-monitor-v2 /usr/local/bin/
  sudo chmod +x /usr/local/bin/rpi-mqtt-monitor-v2
}

main(){
  find_python
  check_and_install_pip
  create_venv
  install_requirements 
  update_config
  create_shortcut

  while true; do
    read -p "Do you want to set up a (c)ron job or a (s)ervice? " cs
    case $cs in
        [Cc]* ) set_cron; break;;
        [Ss]* ) set_service; break;;
        * ) echo "Please answer c for cron or s for service.";;
    esac
  done
  
  printm "Installation is complete."
  echo "rpi-mqtt-monitor-v2 is now running and sending information to your ${finish_message}."
  echo "To see all available options run: rpi-mqtt-monitor-v2 -h in the terminal."
}

main
