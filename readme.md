OpenVPN cascading script

The installed application consists of a total of 3 scripts and 2 services which, when using a compatible VPN provider, enable automatic cascading.
The following providers are known:

* [Perfect Privacy] (https://www.perfect-privacy.com) -> tested
* [oVPN] (https://vcp.ovpn.to/) -> untested
* [ZorroVPN] (https://zorrovpn.com/) -> untested


The connection parameters can be influenced by specifying a maximum number of hops and a min and max time.

Many parameters can be customized within the variable declaration.

## Execution

The following instructions describe the dependencies, installation, directories and customization options for the scripts and services.

### dependencies

Basically, when the installation script is executed, all required packages are checked for their presence and installed if necessary.
These are the following packages.

`` `
tmux
openvpn
resolvconf
psmisc
bc
`` `

### installation

The installation script is started with just one command - the rest is done on its own.

    sudo bash -c "$(wget -qO - https://raw.githubusercontent.com/92VV3M42d3v8/PP_openVPN_cascade/master/install_ovpn_cascading.sh)"

#### First installation
If this is a first-time installation, the instructions in the terminal window must be observed.

#### Update execution
With an update, the script can be executed exactly as already described.
Based on the existence of the main script, it is recognized that this is an update.
All variable declarations are taken from the previously productive script and entered in the new one.
The services are then started again.

### Uninstall
The uninstallation can also be carried out with just one command.
At the end there are no more references, services or information (LOG's ...).


    sudo bash -c "$(wget -qO - https://raw.githubusercontent.com/92VV3M42d3v8/PP_openVPN_cascade/master/uninstall_ovpn_cascading.sh)"


## control

Service management
There are two services for the following scripts:
* Main script
* Watchdog script

Control of the main script using the following service names:

    openvpn-restart-cascading.service


Control of the watchdog script using the following service names:

    openvpn-restart-cascading-watchdog.service


### Declare variables
Only the variables at the beginning of the main script have to be defined.
All variables that are dependent on the watchdog script are automatically adopted when the script / service is started.
The watchdog service is then always restarted.

The main script can e.g. can be edited with nano:

    sudo nano /etc/systemd/system/openvpn_service_restart_cascading.sh


In order for the changes to take effect, the main script service must be restarted using:

    sudo systemctl restart openvpn-restart-cascading.service


Then always check the LOG to see that the new connections are being established:

    less /var/log/ovpn_reconnect/vpnlog_restart.log


## Built With

* NotePad ++
* Love ♥

