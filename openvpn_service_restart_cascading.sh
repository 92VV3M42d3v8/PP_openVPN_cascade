#!/bin/bash
#
### Declare variables ###
#
# Path to the storage of all log files of this script
folder_logpath=/var/log/ovpn_reconnect/
#
# Logfile name for this script (just change the name!)
logfile_script="$folder_logpath"vpnlog_restart.log
#
# Path to the OpenVPN configs that are to be used
path_ovpn_conf=/etc/openvpn/connections/
#
# Path to updown cascading script
path_ovpn_cascade_script=/etc/openvpn/updown.sh
#
# Checkfile for the watchdog service (just change the name!)
checkfile_watchdog="$folder_logpath"exitnode.log
#
# Path to the watchdog script file (openvpn_service_restart_cascading_watchdog.sh)
scriptfile_watchdog=/etc/systemd/system/openvpn_service_restart_cascading_watchdog.sh
#
# minimum connection duration in seconds
mintime=7200
#
# maximum connection duration in seconds
maxtime=10800
#
# How many HOPs to connect?
maxhop=3
#
# Timeout counter (in seconds) for establishing the connection (value is extended by 10 seconds per HOP)
# NOTE: the first connection usually takes '16' seconds
timeoutcount=20
#
### Declare END variables ###

### Definition of functions ###

function cleanup {
	killall openvpn > /dev/null
	sleep 2
	tmux kill-server > /dev/null
	sleep 0.5
	rm -rf "$folder_logpath"log.vpnhop* > /dev/null
	sleep 0.2
}
function kill_primary_process {
	cleanup
	PID=$(systemctl --property="MainPID" show openvpn-restart-cascading.service | cut -d '=' -f 2)
	sleep 0.5
	sudo kill -9 -"$(ps -o pgid= "$PID" | grep -o '[0-9]*')" > /dev/null
}
function kill_watchdog_process {
	PID=$(systemctl --property="MainPID" show openvpn-restart-cascading-watchdog.service | cut -d '=' -f 2)
	sleep 0.5
	sudo kill -9 -"$(ps -o pgid= "$PID" | grep -o '[0-9]*')" > /dev/null
}
function determine_server {
	mapfile -t server_list < <(eval ls -1 "$path_ovpn_conf"'*.conf' | sed 's/,//g' | rev |  cut -d '/' -f 1 | rev)
	server_list_count="${#server_list[@]}"
}
function remux_server_list {
	server_count="${#server_list[@]}"
	random=$(shuf -i 0-$((server_count-1)) -n 1)
	naechster_server=${server_list[$random]}
	server_name=$(echo "$next_server" | cut -d '.' -f1)
	unset 'server_list[$random]'
	server_list_temp=("${server_list[@]}")
	server_list=("${server_list_temp[@]}")
	unset server_list_temp
}
function incr_time {
	inc_timeout=$(("$inc_timeout"+"10"))
}
function get_last_gw {
	# determine the gateway of the previous connection
	gw_previous_hop=$(grep 'VPN: gateway:' "$folder_logpath"'log.vpnhop'"$((hopnr-1))" | sed -e 's/^.\{,36\}//')
	# last gateway has been determined and stored in a variable
}
function write_timestamp {
	echo -e "It is now:\t\t$(date)" >> $logfile_script
}
function get_cur_tim {
	curtim_dat=$(date +"%Y-%m-%dT%H:%M:%S")
	curtim_sec=$(date --date="$curtim_dat" +%s)
}
function get_end_tim {
	curtim_dat=$(date +"%Y-%m-%dT%H:%M:%S")
	curtim_sec=$(date --date="$curtim_dat" +%s)
	endtim_sec=$((curtim_sec+timer))
	endtim_dat=$(date -d @$endtim_sec +"%a%e. %b %H:%M:%S %Z %Y")
}
function vpn_connect_initial_one {
	echo -e "\nVPN connection no. $hopnr is established after:\t\t$server_name" >> $logfile_script
	tmux new -d -s vpnhop"$hopnr" openvpn --config $path_ovpn_conf"$next_server" --script-security 2 --route remote_host --persist-tun --up $path_ovpn_cascade_script --down $path_ovpn_cascade_script --route-noexec \; pipe-pane -o "cat > $folder_logpath'log.#S'"

	# wait until the search string is found following a successful connection
	until grep 'Initialization Sequence Completed' "$folder_logpath"'log.vpnhop'"$hopnr" >> /dev/null;
	do
		sleep 0.2;

		if (( $(echo "$errorcount > $inc_timeout" | bc -l) ));
		then
			echo -e "TIMEOUT: Connection to $hopnr. HOP Server: $server_name NOT successful, try again!" >> $logfile_script
			return=1
			return
		fi
		errorcount=$(echo "$errorcount+0.2" | bc)
	done
	# Connection successfully established
	echo -e "VPN-connection no. $hopnr successfully established to:\t$server_name\n" >> $logfile_script
	return=0
}
function vpn_connect_following_n {
	echo -e "\nVPN-connection no. $hopnr is established after:\t\t$server_name" >> $logfile_script
	tmux new -d -s vpnhop"$hopnr" openvpn --config $path_ovpn_conf"$next_server" --script-security 2 --route remote_host --persist-tun --up $path_ovpn_cascade_script --down $path_ovpn_cascade_script --route-noexec --setenv hopid "$hopnr" --setenv prevgw "$gw_vorheriger_hop" \; pipe-pane -o "cat > $folder_logpath'log.#S'"

	# wait until the search string is found following a successful connection
	until grep 'Initialization Sequence Completed' "$folder_logpath"'log.vpnhop'"$hopnr" >> /dev/null;
	do
		sleep 0.2;

		if (( $(echo "$errorcount > $inc_timeout" | bc -l) ));
		then
			echo -e "TIMEOUT: Connection to $hopnr. HOP Server: $server_name NOT successful, try again!" >> $logfile_script
			return=1
			return
		fi
		errorcount=$(echo "$errorcount+0.2" | bc)
	done
	# Connection to HOP successfully established
	echo -e "VPN-connection no. $hopnr uccessfully established to:\t$server_name\n" >> $logfile_script
	return=0
}
#
### END Definition of functions ###
#
### MAIN PROGRAM ###

# as long as there is no connection, write a wait code for the watchdog
echo "wait" > $checkfile_watchdog

# in the watchdog script enter the same path to the checkfile as in this script
sed -i "/checkfile_watchdog=/c checkfile_watchdog=$checkfile_watchdog" $scriptfile_watchdog
sleep 0.2

# the watchdog script should also be in the same directory as the main script LOG
sed -i "/logfile_watchdog=/c logfile_watchdog=${folder_logpath}watchdog_openvpn_reconnect.log" $scriptfile_watchdog
sleep 0.2

# the watchdog script should also know in which path this script stores the LOG's
sed -i "/folder_logpath=/c folder_logpath=${folder_logpath}" $scriptfile_watchdog
sleep 0.2

# restart the watchdog service so that it knows the new path and runs without errors
kill_watchdog_process
sleep 2

# we need the existing log directory, create it if not already there
if [[ ! -d "$folder_logpath" ]];
then
	mkdir $folder_logpath
fi

# Take over number of maximum HOP's into the Perfect-Privacy-Script
sed -i "/MAX_HOPID=/c MAX_HOPID=$maxhop" $path_ovpn_cascade_script

# check if more connections are desired than Configs available
# this is also how the array with all connections is created
determine_server

if [ "$maxhop" -gt "$server_list_count" ];
then
	{
		echo -e "Maximum HOPs:\t\t\t$maxhop"
		echo -e "Number of Configs in Array:\t$server_list_count"
		echo "MaxHOP must be less than or equal to number of Configs!!!"
		echo "Script is now restarted continuously until the number of Configs fits! Please adjust and restart the service!"
		echo "The Configs must be located here: $path_ovpn_conf"
	} >> $logfile_script
	sleep 20
	exit 1
fi
# Check completed

###  Start outer loop - endless loop ###
while true
do
	# 'k' is the count variable for the array that remembers our connections
	k=0

	# Clean up before the connections start
	cleanup

	# Reset endtime for now to call the loop
	endtim_sec=0

	# Set flag indicating that there is NO connection at the beginning of the loop
	connected_check=0

	# Determine the duration of the connection
	timer=$(shuf -i "$mintime"-"$maxtime" -n 1)

	# Take over timeout variable for this connection session from the variable declaration
	inc_timeout=$timeoutcount

	{
		echo -e "\n\n------------------------------------------------------------------"
		echo "The following connection will be maintained for $timer seconds"
		echo "------------------------------------------------------------------"
	} >> $logfile_script

	write_timestamp

	### Start inner loop ###
	while [[ "$endtim_sec" -eq "0" ]] || [[ "$curtim_sec" -le "$endtim_sec" ]]
	do
		# read current connection status from the checkfile and save it into a variable
		current_state=$(cat $checkfile_watchdog)

		# check, a connection exists / the outgoing server is used
		if wget -qO- icanhazip.com | grep "$current_state" >> /dev/null
		then
			# wait 10 seconds before checking again
			sleep 10
			get_cur_tim
		else
			if [ "$connected_check" -eq "0" ];
			then
				hopnr=1
				errorcount=0

				# Server list must be read in again
				determine_server

				# find the first server and consolidate the array
				remux_server_list

				# establish the initial connection
				vpn_connect_initial_one

				# if connection establishment NOT OK -> try with new server
				while [ ! "$return" -eq "0" ]
				do
					if [ "$(("${#server_list[@]}"-"$maxhop"+"hopnr"))" -gt "0" ];
					then
						tmux kill-session -t vpnhop"$hopnr"
						rm -rf "$folder_logpath"log.vpnhop"$hopnr"
						errorcount=0

						# Determine the first server again and consolidate the array
						remux_server_list

						# retry the initial connection
						vpn_connect_initial_one
					else
						echo -e "\n\nconnection problem!" >> $logfile_script
						echo -e "-------------------" >> $logfile_script
						write_timestamp
						echo -e "\nNo functional servers are left over!\n" >> $logfile_script
						echo -e "Now start all over again!" >> $logfile_script
						exit 1
					fi
				done
				# Initial connection is established

				# Store server name of the connection in an array
				con_servers[$k]=$server_name
				k=$((k+1))
				hopnr=$((hopnr+1))

				# should further connections now be established?
				# Falls maxhop > 1, then go!
				if [ "$maxhop" -gt "1" ];
				then
					echo -e "==> MaxHOP set to $maxhop now follow $((maxhop-1)) connection(en)!\n" >> $logfile_script

					while [ "$hopnr" -le "$maxhop" ]
					do
						errorcount=0

						# we need the previous gateway for the following connections
						get_last_gw

						echo -e "The gateway of HOP no. $((hopnr-1)) is:\t\t\t$gw_previous_hop\n" >> $logfile_script

						# each further connection should receive 10 seconds more timeout
						incr_time

						# determine the next server and consolidate the array afterwards
						remux_server_list

						# now establish the following connection
						vpn_connect_following_n

						# if connection establishment NOT OK -> try with new server
						while [ ! "$return" -eq "0" ]
						do
							if [ "$(("${#server_list[@]}"-"$maxhop"+"hopnr"))" -gt "0" ];
							then
								tmux kill-session -t vpnhop"$hopnr"
								rm -rf "$folder_logpath"log.vpnhop"$hopnr"
								errorcount=0

								# Determine the first server again and consolidate the array
								remux_server_list

								# retry the initial connection
								vpn_connect_following_n
							else
								echo -e "\n\nconnection problem!" >> $logfile_script
								echo -e "-------------------" >> $logfile_script
								write_timestamp
								echo -e "\nNo functional servers are left over!\n" >> $logfile_script
								echo -e "Now start all over again!" >> $logfile_script
								exit 1
							fi
						done

						# Store server names of the respective connections in an array
						con_servers[$k]='==>'
						k=$((k+1))
						con_servers[$k]=$server_name
						k=$((k+1))
						hopnr=$((hopnr+1))
					done
				else
					echo -e "MaxHOP set to $maxhop no further connections needed!" >> $logfile_script
				fi
				echo "$(wget -qO- icanhazip.com)" > $checkfile_watchdog

				if [ "$maxhop" -gt "1" ];
				then
					echo -e "Cascade now exists as follows:" >> $logfile_script
					echo "${con_servers[*]}" >> $logfile_script
				fi

				# determine the end time (time NOW + determined random value)
				get_end_tim

				echo -e "\n\nConnection start:\t$(date)" >> $logfile_script
				echo -e "Connection history:\t$endtim_dat" >> $logfile_script

				# Now we are finally connected and set a flag as a flag
				connected_check=1
			else
				# if the flag for connected_check is set to 1 and we slide in here, something is wrong with the connection
				echo -e "\n\nconnection problem!" >> $logfile_script
				echo -e "-------------------" >> $logfile_script
				write_timestamp
				echo -e "\nWaiting for watchdog service until processes are restarted!" >> $logfile_script
				sleep 20

				# ATTENTION: if the watchdog doesn't run, just quit from here
				exit 1
			fi
		fi
	done
	# get out of the loop, because the countdown has expired, now remove everything and then go back to the beginning of the loop (outer loop)
	### End inner loop ###

	# tell the watchdog to wait again until the next connect
	echo "wait" > $checkfile_watchdog

	echo "Time up! Connections are now terminated!" >> $logfile_script

	# If the LOG is larger than 20MB, empty this
	if [[ "$(wc -c $logfile_script | cut -d ' ' -f 1)" -gt "20480" ]];
	then
		echo "" > $logfile_script
	fi

	# delete the array with the stored servers
	unset con_servers

	# Now it goes back to the beginning of the outer loop
done
### End outer loop ###
