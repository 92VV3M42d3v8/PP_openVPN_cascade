#!/bin/bash
#
# ## Declare variables
#
sudo apt-get install openvpn tmux bc psmisc resolvconf
# Create folder path
sudo mkdir /rw/config/vpn/

# Storage location for this installation log
install_log=/rw/config/vpn/install_ovpn_cascade.log
#
# Path for storing the scripts
scriptpath_SVC=/rw/config/vpn
#
# Path for storing the service files
servicepath=/lib/systemd/system
#
# Path for storing the cascading script
scriptpath_UPD=/rw/config/vpn
#
# Download link main script
DL_PRIM_SCR=https://raw.githubusercontent.com/92VV3M42d3v8/PP_openVPN_cascade/master/openvpn_service_restart_cascading.sh
#
# Download link watchdog script
DL_WATC_SCR=https://raw.githubusercontent.com/92VV3M42d3v8/PP_openVPN_cascade/master/openvpn_service_restart_cascading_watchdog.sh
#
# Download link main script service file
DL_PRIM_SRV=https://raw.githubusercontent.com/92VV3M42d3v8/PP_openVPN_cascade/master/openvpn-restart-cascading.service
#
# Download link watchdog script service file
DL_WATC_SRV=https://raw.githubusercontent.com/92VV3M42d3v8/PP_openVPN_cascade/master/openvpn-restart-cascading-watchdog.service
#
# Download link PP cascading script
DL_CASC_SCR=https://raw.githubusercontent.com/92VV3M42d3v8/PP_openVPN_cascade/master/updown.sh
#
# ## END declare variables

# ## Features ###
function search_and_replace {
	line_num=($(grep -n -m 1 $1 $2 | cut -d':' -f 1))
	sed -i ""$line_num"s#.*#"$3"#" $4
}
# ## END functions ###

# Basically assume that NO update will be carried out
update_check=0

# Blank screen
clear

# Clear LOG, if available
if [[ -f $install_log ]];
then
	rm $install_log
fi

printf  "\n\nScript to install the automatic openVPN cascading services" 2>&1 | tee -a $install_log
printf  "\n ---------------------------------------------- ------------------------ \n\n "  2>&1 | tee -a $install_log

if  !  command -v dpkg >> /dev/null
then
	printf  "Packagemanager 'dpkg' is missing!" 2>&1 | tee -a $install_log
	printf  "\nPlease install 'dpkg' first and then run the script again." 2>&1 | tee -a $install_log
	printf  "\nThe installation will be canceled!" 2>&1 | tee -a $install_log
	printf  "\n\n "
	exit
fi

printf  "... the process takes less than a minute.\n\n" 2>&1 | tee -a $install_log

# Update package data and repository
apt-get update -qq

# ## install necessary packages
# check whether 'tmux' is installed -> if not, install!
#dpkg -l | grep ^ ii | awk ' {print $ 2} '  | grep -w " tmux "  > / dev / null

#if [ $?  -eq  " 1 " ] ;
#then
#	apt-get install tmux -qq > / dev / null
#	printf  " ==> tmux installed! \ n "  2> & 1  | tee -a $ install_log
#else
#	printf  " ==> tmux is available! \ n "  2> & 1  | tee -a $ install_log
#fi

# check whether 'openvpn-client' is installed -> if not, install!
#dpkg -l | grep ^ ii | awk ' {print $ 2} '  | grep -w " openvpn "  > / dev / null

#if [ $?  -eq  " 1 " ] ;
#then
#	apt-get install openvpn -qq > / dev / null
#	printf  " ==> openvpn installed! \ n "  2> & 1  | tee -a $ install_log
#else
#	printf  " ==> openvpn exists! \ n "  2> & 1  | tee -a $ install_log
#fi

# check whether 'resolvconf' is installed -> if not, install!
#dpkg -l | grep ^ ii | awk ' {print $ 2} '  | grep -w " resolvconf "  > / dev / null

#if [ $?  -eq  " 1 " ] ;
#then
#	apt-get install resolvconf -qq > / dev / null
#	printf  " ==> resolvconf installed! \ n "  2> & 1  | tee -a $ install_log
#else
#	printf  " ==> resolvconf exists! \ n "  2> & 1  | tee -a $ install_log
#fi

# check whether 'psmisc' is installed -> if not, install!
#dpkg -l | grep ^ ii | awk ' {print $ 2} '  | grep -w " psmisc "  > / dev / null

#if [ $?  -eq  " 1 " ] ;
#then
#	apt-get install psmisc -qq > / dev / null
#	printf  " ==> psmisc installed! \ n "  2> & 1  | tee -a $ install_log
#else
#	printf  " ==> psmisc exists! \ n "  2> & 1  | tee -a $ install_log
#fi

# check whether 'bc' is installed -> if not, install!
#dpkg -l | grep ^ ii | awk ' {print $ 2} '  | grep -w " bc "  > / dev / null

#if [ $?  -eq  " 1 " ] ;
#then
#	apt-get install bc -qq > / dev / null
#	printf  " ==> bc installed! \ n \ n "  2> & 1  | tee -a $ install_log
#else
#	printf  " ==> bc exists! \ n "  2> & 1  | tee -a $ install_log
#fi

# ## necessary packages installed

# which directory are we in?
curdir="${PWD}"

# Create working directory
mkdir $curdir'/'OVPN_SWITCH

# Download the necessary files
# Save filenames in variables
wget -q -P $curdir'/OVPN_SWITCH/' $DL_PRIM_SCR > /dev/null
FILE_DL_PRIM_SCR=($(echo $DL_PRIM_SCR | rev | cut -d '/' -f 1 | rev))
wget -q -P $curdir'/OVPN_SWITCH/' $DL_WATC_SCR > /dev/null
FILE_DL_WATC_SCR=($(echo $DL_WATC_SCR | rev | cut -d '/' -f 1 | rev))
wget -q -P $curdir'/OVPN_SWITCH/' $DL_PRIM_SRV > /dev/null
FILE_DL_PRIM_SRV=($(echo $DL_PRIM_SRV | rev | cut -d '/' -f 1 | rev))
wget -q -P $curdir'/OVPN_SWITCH/' $DL_WATC_SRV > /dev/null
FILE_DL_WATC_SRV=($(echo $DL_WATC_SRV | rev | cut -d '/' -f 1 | rev))
wget -q -P $curdir'/OVPN_SWITCH/' $DL_CASC_SCR > /dev/null
FILE_DL_CASC_SCR=($(echo $DL_CASC_SCR | rev | cut -d '/' -f 1 | rev))

# if an update is carried out, first stop the services
systemctl --full --type service --all | grep -q openvpn-restart-cascading.service
if [ $? -eq "0" ];
then
	systemctl stop openvpn-restart-cascading.service > /dev/null
fi

systemctl --full --type service --all | grep -q openvpn-restart-cascading-watchdog.service
if [ $? -eq "0" ];
then
	systemctl stop openvpn-restart-cascading-watchdog.service > /dev/null
fi

sleep 2

# store the files in the target directories and check beforehand whether the main script is already available (in the event of an update)
# if available, first transfer the variables to the new, downloaded script
if [[ -f "$scriptpath_SVC/$FILE_DL_PRIM_SCR" ]];
then
	update_check=1

	cur_folder_logpath=($(grep -m 1 "folder_logpath=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace folder_logpath= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_folder_logpath $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_logfile_script=($(grep -m 1 "logfile_script=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace logfile_script= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_logfile_script $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_path_ovpn_conf=($(grep -m 1 "path_ovpn_conf=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace path_ovpn_conf= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_path_ovpn_conf $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_path_ovpn_cascade_script=($(grep -m 1 "path_ovpn_cascade_script=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace path_ovpn_cascade_script= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_path_ovpn_cascade_script $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_checkfile_watchdog=($(grep -m 1 "checkfile_watchdog=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace checkfile_watchdog= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_checkfile_watchdog $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_scriptfile_watchdog=($(grep -m 1 "scriptfile_watchdog=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace scriptfile_watchdog= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_scriptfile_watchdog $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_mintime=($(grep -m 1 "mintime=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace mintime= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_mintime $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_maxtime=($(grep -m 1 "maxtime=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace maxtime= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_maxtime $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_maxhop=($(grep -m 1 "maxhop=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace maxhop= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_maxhop $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

	cur_timeoutcount=($(grep -m 1 "timeoutcount=" "$scriptpath_SVC"'/'"$FILE_DL_PRIM_SCR"))
	search_and_replace timeoutcount= $scriptpath_SVC/$FILE_DL_PRIM_SCR $cur_timeoutcount $curdir/OVPN_SWITCH/$FILE_DL_PRIM_SCR

fi

# save the files in the target directories
mv -f $curdir'/OVPN_SWITCH/'$FILE_DL_PRIM_SCR $scriptpath_SVC
mv -f $curdir'/OVPN_SWITCH/'$FILE_DL_WATC_SCR $scriptpath_SVC
mv -f $curdir'/OVPN_SWITCH/'$FILE_DL_PRIM_SRV $servicepath
mv -f $curdir'/OVPN_SWITCH/'$FILE_DL_WATC_SRV $servicepath
mv -f $curdir'/OVPN_SWITCH/'$FILE_DL_CASC_SCR $scriptpath_UPD

# make the scripts executable
chmod +x $scriptpath_SVC'/'$FILE_DL_PRIM_SCR
chmod +x $scriptpath_SVC'/'$FILE_DL_WATC_SCR
chmod +x $scriptpath_UPD'/'$FILE_DL_CASC_SCR

# make the services executable and activate them
chmod +x $servicepath'/'$FILE_DL_PRIM_SRV
chmod +x $servicepath'/'$FILE_DL_WATC_SRV

systemctl daemon-reload

systemctl enable $FILE_DL_PRIM_SRV
systemctl enable $FILE_DL_WATC_SRV

# Delete working directory
rm -r $curdir'/'OVPN_SWITCH

# Status output

path_ovpn_conf=($(grep -m 1 'path_ovpn_conf=' $scriptpath_SVC'/'$FILE_DL_PRIM_SCR | rev | cut -d '=' -f 1 | rev))
folder_logpath=($(grep -m 1 'folder_logpath=' $scriptpath_SVC'/'$FILE_DL_PRIM_SCR | rev | cut -d '=' -f 1 | rev))

if [ $update_check -eq "1" ];
then
	printf "\n------------------------------------------------" 2>&1 | tee -a $install_log
        printf "\nUpdate SUCCESSFULLY completed!" 2>&1 | tee -a $install_log
	printf "\nServices are started again!" 2>&1 | tee -a $install_log
	printf "\n------------------------------------------------" 2>&1 | tee -a $install_log
	printf "\n\nPerfectPrivacy configurations are still located in the following directory:\n==> $path_ovpn_conf" 2>&1 | tee -a $install_log
	printf "\nNote: all configurations (*.conf) in this directory are used!" 2>&1 | tee -a $install_log
	printf "\n\nOther steps necessary!" 2>&1 | tee -a $install_log
	printf "\n---------------------------------" 2>&1 | tee -a $install_log

	printf "\nService management using the following commands:" 2>&1 | tee -a $install_log
	printf "\n\t- sudo systemctl start|stop|restart openvpn-restart-cascading.service" 2>&1 | tee -a $install_log
	printf "\n\t- sudo systemctl start|stop|restart openvpn-restart-cascading-watchdog.service" 2>&1 | tee -a $install_log

	systemctl start openvpn-restart-cascading.service > /dev/null
	systemctl start openvpn-restart-cascading-watchdog.service > /dev/null
else
	eval mkdir -p $path_ovpn_conf
	printf "\n------------------------------------------------" 2>&1 | tee -a $install_log
	printf "\nInstallation SUCCESSFULLY completed!" 2>&1 | tee -a $install_log
	printf "\nInstalled services NOT yet started!" 2>&1 | tee -a $install_log
	printf "\n------------------------------------------------" 2>&1 | tee -a $install_log
	printf "\n\nPerfectPrivacy OpenVPN configurations please store in the following directory:\n==> $path_ovpn_conf" 2>&1 | tee -a $install_log
	printf "\nNote: all configurations (*.conf) in this directory are used!" 2>&1 | tee -a $install_log
	printf "\n\nNow perform the following steps!" 2>&1 | tee -a $install_log
	printf "\nBehind the ':' are the commands" 2>&1 | tee -a $install_log
	printf "\n-----------------------------------" 2>&1 | tee -a $install_log
	printf "\n\nDownloading the PerfectPrivacy configurations" 2>&1 | tee -a $install_log
	printf "\n\t- Change to the target directory: cd $path_ovpn_conf" 2>&1 | tee -a $install_log
	printf "\n\t- Download the configurations: sudo wget --content-disposition https://www.perfect-privacy.com/downloads/openvpn/get?system=linux" 2>&1 | tee -a $install_log
	printf "\n\t- Extract the files: sudo unzip -j linux_op24_udp_v4_AES256GCM_AU_in_ci.zip" 2>&1 | tee -a $install_log
	printf "\nCreate a file with the login data" 2>&1 | tee -a $install_log
	printf "\n\t- Create the file in the directory where we are located: sudo nano $path_ovpn_conf"password.txt"" 2>&1 | tee -a $install_log
	printf "\n\t- Enter login data into this file: first line ONLY the username, second line ONLY the password" 2>&1 | tee -a $install_log
	printf "\n\t- Save and close file: Ctrl+X -> then confirm with 'J' or 'y'" 2>&1 | tee -a $install_log
	printf "\nEntry the just created 'password.txt' into the downloaded Configs" 2>&1 | tee -a $install_log
	printf "%s\n\t- Edit all Configs with the path to 'password.txt: sudo find *.conf -type f -exec sed -i %s""\"/auth-user-pass/c auth-user-pass $path_ovpn_conf"password.txt"\" {} \;" 2>&1 | tee -a $install_log
	printf "\n\\nFinally, the system must be rebooted: sudo reboot" 2>&1 | tee -a $install_log
	printf "\n\nThe installed services are called 'openvpn-restart-cascading.service' and 'openvpn-restart-cascading-watchdog.service'" 2>&1 | tee -a $install_log
	printf "\nService management using the following commands:" 2>&1 | tee -a $install_log
	printf "\n\t- sudo systemctl start|stop|restart openvpn-restart-cascading.service" 2>&1 | tee -a $install_log
	printf "\n\t- sudo systemctl start|stop|restart openvpn-restart-cascading-watchdog.service" 2>&1 | tee -a $install_log
	printf "\n\nAfter the reboot the log directory is located here: $folder_logpath" 2>&1 | tee -a $install_log
	printf "\n\nThis output log can be found here: $install_log" 2>&1 | tee -a $install_log
	printf "\n\nSome of these steps were taken from the following instructions: https://www.perfect-privacy.com/de/manuals/linux_openvpn_terminal" 2>&1 | tee -a $install_log
fi

