#! / bin / bash
#
# ## Declare variables ###
#
# Path to the storage of all log files of the main script
folder_logpath = / rw / config / vpn /
#
# Log file for this watchdog script
logfile_watchdog = " $ folder_logpath " watchdog_openvpn_reconnect.log
#
# Check file for the watchdog service
checkfile_watchdog = " $ folder_logpath " exitnode.log
#
# ## END declare variables ###
#
# ## Definition of functions ###
#
function  checkfile {
	if [ -f  " $ checkfile_watchdog " ] ;
	then
		chkfl = " 1 "
	else
		chkfl = " 0 "
	fi
}
function  get_state {
	current_state = $ ( cat $ checkfile_watchdog )
	sleep 1
}
function  check_inactivity {
	if grep " Inactivity timeout (--ping-restart), restarting "  " $ folder_logpath " log.vpnhop *
	then
		{
			echo -e " \ n ---------- ATTENTION ---------- "
			echo -e " It's now $ ( date ) "
			echo -e " At least one server in the cascade can no longer be reached! "
			echo -e " Now restart services so that a safe state can be restored! "
		} >>  $ logfile_watchdog
		kill_primary_process
	fi
}
function  check_state {
	wget -O - -q --tries = 3 --timeout = 20 ipv4.icanhazip.com | grep " $ current_state "  >> / dev / null
	RET = $?
	sleep 4
}
function  cleanup {
	sudo killall openvpn
	sleep 2
	sudo tmux kill-server
	sleep 0.5
}
function  kill_primary_process {
	cleanup
	PID = $ ( sudo systemctl --property = " MainPID " show openvpn-restart-cascading.service | cut -d ' = ' -f 2 )
	sleep 0.2
	sudo kill -9 - " $ ( ps -o pgid = " $ PID "  | grep -o ' [0-9] * ' ) "  > / dev / null
}
function  log_delete {
	if [[ " $ ( wc -c $ logfile_watchdog  | cut -d '  ' -f 1 ) "  -gt  " 20480 " ]] ;
	then
		echo  " "  >  $ logfile_watchdog
	fi
}
function  continuously_check {
	while [ -f  " $ checkfile_watchdog " ]
	do
		# save the current file content in a variable
		get_state

		echo -e " \ n \ nThe connection has been established since: \ t \ t $ ( date ) "  >>  $ logfile_watchdog
		echo -e " with public IP: \ t \ t \ t $ current_state "  >>  $ logfile_watchdog

		check_inactivity
		check_state

		while [ $ RET  -eq  " 0 " ]
		do
			check_inactivity
			get_state
			check_state
		done

		get_state
		if [ !  " $ current_state "  ==  " Wait " ] ;
		then
			{
				echo -e " \ n ---------- ATTENTION ---------- "
				echo -e " It's now $ ( date ) "
				echo -e " Public IP has changed: \ t $ ( wget -O - -q --tries = 3 --timeout = 20 ipv4.icanhazip.com ) "
				echo -e " Now restart services so that a safe state can be restored! "
			} >>  $ logfile_watchdog
			kill_primary_process
			sudo rm $ checkfile_watchdog
		fi
		return
	done
}
#
# ## END definition of functions ###
#
# ## MAIN PROGRAM ###
timeout = 0

while  true
do
	# If the LOG is bigger than 20MB, empty it
	log_delete

	checkfile

	case  " $ chkfl "  in
		# File exists and can be continuously evaluated
		1)
			get_state
			case  " $ current_state "  in
				Waiting)
					sleep 5
					timeout = 0
					;;
				* )
					continuously_check
					timeout = 0
					;;
			esac
			;;

		# File does not yet exist, check again
		0)

			sleep 2
			timeout = $ (( "timeout" + " 2 " ))

			# if the file does not yet exist after a certain counter, something is wrong
			# restart the primary process in this case
			if [ " $ timeout "  -eq  " 10 " ]
			then
				kill_primary_process
			fi
			;;
	esac
done
