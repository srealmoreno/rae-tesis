#!/bin/bash

# gns3-server gns3-gui virtualbox docker vpcs dynamips wireshark-qt wireshark-cli qemu libvirt ubridge

function msg_ok {
	echo -e "\e[42;30m   OK   \e[m $*"
}

function msg_info() {
	echo -e "\e[44;30m  INFO  \e[m $*"
}

function msg_warn() {
	echo -e "\e[43;30m  WARN  \e[m $*"
}

function msg_error() {
	echo -e "\e[41m ERROR  \e[m $*" >&2
	exit 1
}

function create_window() {
	local -i LINES

	# shellcheck disable=SC2154
	if [ "$DEBIAN_FRONTEND" == 'noninteractive' ]; then
		return 0
	fi

	LINES=$(tput lines)

	# Create a new window
	tput smcup

	# Set window size TOP -1 BOTTOM -2 for window name
	tput csr 1 $((LINES - 2))

	# Set window name (TOP)
	tput cup 0 0
	echo -e "\e[44;30m $*\e[K\e[m"

	# Set window size (BOTTOM)
	tput cup "$LINES" 0
	echo -e "\e[44;30m $*\e[K\e[m"

	# Set cursor position (BOTTOM)
	tput cup 1 0
}

function close_window() {
	local -r -i LAST_CODE=$?
	local -i LINES

	if [ "$LAST_CODE" -ne 0 ]; then
		press_any_key
	fi

	if [ "$DEBIAN_FRONTEND" == 'noninteractive' ]; then
		return "$LAST_CODE"
	fi

	LINES=$(tput lines)

	# Delete window
	tput rmcup

	# Save cursor position
	tput sc

	# Restore winow size
	tput csr 0 "$LINES"

	# Restore cursor position
	tput rc

	return "$LAST_CODE"
}

function prompt_yes_or_no() {
	local -r PROMPT="$1"
	local -l answer

	if [ "$DEBIAN_FRONTEND" == 'noninteractive' ]; then
		return 0
	fi

	while true; do
		read -r -p "$PROMPT [y/n] " answer
		case $answer in
		y | yes)
			tput rc
			tput ed
			return 0
			;;
		n | no)
			tput rc
			tput ed
			return 1
			;;
		*)
			echo 'Please answer yes or no.'
			tput cuu 2
			tput el
			;;
		esac
	done
}

function close_graphical_session() {
	msg_warn 'is required to close the graphical session.'

	if [ "$DEBIAN_FRONTEND" == 'noninteractive' ]; then
		msg_warn 'Please close the graphical session manually.'
		return 0
	fi

	tput sc
	if prompt_yes_or_no 'Do you want to close it now?'; then
		# shellcheck disable=SC2154
		loginctl terminate-session "$XDG_SESSION_ID" || pkill -u "$SUDO_USER"
	else
		msg_warn 'Please close the graphical session manually.'
	fi
}

function press_any_key() {
	# Set white foreground
	tput setaf 7
	# Set background to red
	tput setab 1
	# Invisible cursor
	tput civis

	if [ "$DEBIAN_FRONTEND" != 'noninteractive' ]; then
		read -n 1 -s -r -p 'Press any key to continue...'
	fi

	# Reset foreground
	tput sgr0
	# Reset background
	tput setab 0
	# Reset cursor
	tput cnorm
}

function verify_sudo() {
	if [ "$EUID" -ne 0 ]; then
		msg_error 'You must run this script as root'
	fi

	# shellcheck disable=SC2154
	if [ -z "$SUDO_USER" ] || [ -z "$SUDO_GID" ] || [ -z "$SUDO_UID" ]; then
		msg_error 'You must run this script with sudo'
	fi

	if [ "$SUDO_USER" == 'root' ]; then
		msg_error 'Running as root is not allowed'
	fi
}

function get_distro() {
	msg_info 'Obtaining information about your distribution...'

	if [ ! -f /etc/os-release ]; then
		msg_error 'Unable to detect your distro '/etc/os-release' file not found'
	fi

	# shellcheck source=/dev/null
	source /etc/os-release

	if [ "$ID" != 'arch' ] && [ "$ID_LIKE" != 'arch' ]; then
		msg_error "Unable to detect your distro '$ID' not supported. Only arch and its derivatives are supported"
	fi

	msg_ok "distro detected: $PRETTY_NAME ($ID)"
}

function install_yay() {
	msg_info 'Installing yay...'

	if command -v yay >/dev/null 2>&1; then
		msg_ok 'yay already installed'
		return 0
	fi

	create_window 'Installing yay...'

	pacman -Sy --noconfirm --needed git binutils fakeroot make gcc &&
		runuser -u "$SUDO_USER" git clone https://aur.archlinux.org/yay.git &&
		cd yay &&
		runuser -u "$SUDO_USER" -- makepkg --noconfirm --needed -si &&
		cd .. &&
		rm -rf yay

	close_window

	if [ $? -eq 0 ]; then
		msg_ok 'yay installed'
	else
		msg_error 'yay installation failed'
	fi
}

function install_dependencies() {
	msg_info 'Installing dependencies'

	create_window 'Installing dependencies...' "${YAY_DEPENDENCIES_LIST[@]}"

	runuser -u "$SUDO_USER" -- yay -Sy --noconfirm --needed "${YAY_DEPENDENCIES_LIST[@]}"

	close_window

	if [ $? -eq 0 ]; then
		msg_ok 'Dependencies installed'
	else
		msg_error 'Dependencies not installed'
	fi
}

function add_gns3() {
	LIST_GROUPS+=(
		libvirt
		kvm
		wireshark
	)

	YAY_LIST_INSTALL+=(
		gns3-gui
		gns3-server
	)

}

function add_docker() {
	LIST_GROUPS+=(
		docker
	)

	YAY_LIST_INSTALL+=(
		docker
	)
}

function add_virtualbox() {
	LIST_GROUPS+=(
		vboxusers
	)

	YAY_LIST_INSTALL+=(
		virtualbox
	)
}

function install_yay_list() {
	msg_info 'Installing packages'

	create_window 'Installing Packages...' "${YAY_LIST_INSTALL[@]}"

	runuser -u "$SUDO_USER" -- yay -Sy --noconfirm --needed "${YAY_LIST_INSTALL[@]}"

	close_window

	if [ $? -eq 0 ]; then
		msg_ok 'Packages installed'
	else
		msg_error 'Packages not installed'
	fi
}

function add_user_to_groups() {
	local group

	msg_info 'Adding user to groups'

	for group in "${LIST_GROUPS[@]}"; do
		create_window "Adding user to group '$group'"

		usermod -a -G "$group" "$SUDO_USER"

		close_window

		if [ $? -ne 0 ]; then
			msg_warn "Unable to add user '$SUDO_USER' to group '$group'"
		fi
	done && msg_ok 'User added to groups'
}

function import_docker_image() {
	local -a docker_images
	local image

	docker_images=("$@")

	msg_info 'Importing docker images'
	for image in "${docker_images[@]}"; do
		create_window 'Importing image...' "$image"

		docker pull "$image"

		close_window

		if [ $? -eq 0 ]; then
			msg_ok "Image '$image' imported"
		else
			msg_warn "Image '$image' not imported"
		fi
	done
}

function create_gns3_template() {
	local -nl type="$1"
	local -A computer router switch

	if [[ ! "$1" =~ ^(computer|router|switch)$ ]]; then
		msg_error "Invalid type '$type', only 'computer', 'router' and 'switch' are supported"
	fi

	# shellcheck disable=SC2034
	computer=(
		[default_name_format]='pc{0}'
		[symbol]=':/symbols/classic/computer.svg'
		[category]='guest'
		[name]='pc_docker'
		[adapters]='1'
		[extra_volumes]='["/save", "/etc/network", "/etc/default", "/root"]'
		[template_id]='aaaabbbb-cccc-dddd-eeee-ffff12345678'
	)

	# shellcheck disable=SC2034
	router=(
		[default_name_format]='r{0}'
		[symbol]=':/symbols/classic/router.svg'
		[category]="router"
		[name]='router_docker'
		[adapters]='5'
		[extra_volumes]='["/save","/etc/network","/etc/default","/etc/dhcp","/etc/frr","/root"]'
		[template_id]='aaaabbbb-cccc-dddd-eeee-ffff12345677'
	)

	# shellcheck disable=SC2034
	switch=(
		[default_name_format]='s{0}'
		[symbol]=':/symbols/classic/ethernet_switch.svg'
		[category]='switch'
		[name]='switch_docker'
		[adapters]='8'
		[extra_volumes]='["/save","/etc/network","/etc/default","/root"]'
		[template_id]='aaaabbbb-cccc-dddd-eeee-ffff12345676'
	)

	cat <<-EOF
		{
			"default_name_format": "${type[default_name_format]}",
			"usage": "",
			"symbol": "${type[symbol]}",
			"category": "${type[category]}",
			"start_command": "",
			"name": "${type[name]}",
			"image": "$DOCKER_IMAGE",
			"adapters": ${type[adapters]},
			"custom_adapters": [],
			"environment": "",
			"console_type": "telnet",
			"console_auto_start": true,
			"console_resolution": "800x600",
			"console_http_port": 80,
			"console_http_path": "/",
			"extra_hosts": "",
			"extra_volumes": ${type[extra_volumes]},
			"compute_id": "local",
			"template_id": "${type[template_id]}",
			"template_type": "docker",
			"builtin": false
		}
	EOF
}

function get_gns3_controller_path() {
	local log
	export GREP_COLOR='0;30;44'

	create_window 'Getting GNS3 controller path'

	while read -r log; do
		gns3_controller_path=$(grep -oiP 'Load controller configuration file \K.*' <<<"$log")
		if [ $? -eq 0 ]; then
			grep --color=always 'Load controller configuration file .*' <<<"$log"
			msg_info "Controller catched!"
			kill $!
			wait $! >/dev/null 2>&1
			break
		fi
		echo "$log"
	done < <(timeout 5 runuser -u "$SUDO_USER" gns3server 2>&1)

	unset GREP_COLOR

	if [ "$gns3_controller_path" != '' ]; then
		close_window
	else
		press_any_key
		close_window
		msg_error "Unable to get controller configuration file"
	fi
}

function import_gns3_templates() {
	local gns3_controller_path gns3_controller
	local name changes=false
	local -A templates

	msg_info 'Importing templates for GNS3'

	get_gns3_controller_path

	templates=(
		[computer]=$(create_gns3_template computer)
		[router]=$(create_gns3_template router)
		[switch]=$(create_gns3_template switch)
	)

	gns3_controller=$(<"$gns3_controller_path")

	for name in "${!templates[@]}"; do
		local template template_id template_name
		template=${templates[$name]}

		template_id=$(jq -r '.template_id' <<<"$template")
		template_name=$(jq -r '.name' <<<"$template")

		exits=$(jq -r ".templates[] | select(.template_id == \"${template_id}\" or .name == \"${template_name}\")" <<<"$gns3_controller")

		if [ $? -ne 0 ]; then
			msg_error "Unable to parse GNS3 controller configuration file"
		fi

		if [ "$exits" == '' ]; then
			msg_info "Creating template '$name'"
			gns3_controller=$(jq ".templates += [$template]" <<<"$gns3_controller")

			if [ $? -eq 0 ]; then
				msg_ok
				changes=true
			else
				msg_warn "Unable to create template '$name'"
			fi
		else
			msg_ok "Template '$name' already imported"
		fi
	done

	if $changes; then
		local -r date_now=$(date '+%Y-%m-%d %H:%M:%S')
		# shellcheck disable=SC2015
		mv "$gns3_controller_path" "${gns3_controller_path}-${date_now}.bak" &&
			jq . <<<"$gns3_controller" >"$gns3_controller_path" &&
			msg_ok "Templates imported" || msg_warn "Unable to import templates, error while writing configuration file"
		chown "$SUDO_USER":"$SUDO_USER" "$gns3_controller_path" "${gns3_controller_path}-${date_now}.bak"
	fi
}

function show_help() {
	cat <<-EOF
		usage: sudo $0 [-h] [-a] [-d] [-g] [-v] [-i] [-t]
		tools installer for RAE labs - UNAN León

		optional arguments:
		  -h, --help                   show this help message and exit
		  -a, --all                    install all tools, import docker images and gns3 templates
		  -d, --install-docker         install docker
		  -g, --install-gns3           install gns3
		  -v, --install-virtualbox     install virtualbox
		  -i, --import-docker-image    import docker image ($DOCKER_IMAGE)
		  -t, --import-gns3-templates  import templates for gns3 (pc, router, switch)
	EOF
	exit 0
}

function arguments_parse() {
	f_install_docker=false
	f_install_gns3=false
	f_install_virtualbox=false
	f_import_docker_image=false
	f_import_gns3_templates=false

	if [ $# -eq 0 ]; then
		show_help
	fi

	while [ $# -gt 0 ]; do
		case "$1" in
		-h | --help)
			show_help
			;;
		-a | --all)
			f_install_docker=true
			f_install_gns3=true
			f_install_virtualbox=true
			f_import_docker_image=true
			f_import_gns3_templates=true
			shift
			;;
		-d | --install-docker)
			f_install_docker=true
			shift
			;;
		-g | --install-gns3)
			f_install_gns3=true
			shift
			;;
		-v | --install-virtualbox)
			f_install_virtualbox=true
			shift
			;;
		-i | --import-docker-image)
			f_import_docker_image=true
			shift
			;;
		-t | --import-gns3-templates)
			f_import_gns3_templates=true
			shift
			;;
		*)
			msg_error "Invalid option: $1"
			;;
		esac
	done
}

function install() {
	get_distro

	if $f_install_docker || $f_install_gns3 || $f_install_virtualbox; then
		install_yay
	fi

	if $f_install_gns3; then
		YAY_DEPENDENCIES_LIST+=(
			docker
			vpcs
			dynamips
			wireshark-qt
			wireshark-cli
			qemu
			libvirt
			ubridge
		)
	fi

	if $f_import_gns3_templates; then
		YAY_DEPENDENCIES_LIST+=(
			jq
		)
	fi

	if [ ${#YAY_DEPENDENCIES_LIST[@]} -gt 0 ]; then
		install_dependencies
	fi

	if $f_install_docker; then
		add_docker
	fi

	if $f_install_gns3; then
		add_gns3
	fi

	if $f_install_virtualbox; then
		add_virtualbox
	fi

	if $f_install_docker || $f_install_gns3 || $f_install_virtualbox; then
		install_yay_list
		add_user_to_groups
	fi

	if $f_import_docker_image; then
		import_docker_image "$DOCKER_IMAGE"
	fi

	if $f_import_gns3_templates; then
		import_gns3_templates
	fi
}

function main() {
	trap 'true;close_window' EXIT

	# Distro variables
	local ID ID_LIKE PRETTY_NAME

	local -r DOCKER_IMAGE='srealmoreno/rae-tesis:latest'
	local -a YAY_DEPENDENCIES_LIST LIST_GROUPS YAY_LIST_INSTALL

	# Flags of arguments
	local f_install_docker f_install_gns3 f_install_virtualbox
	local f_import_docker_image f_import_gns3_templates

	verify_sudo
	arguments_parse "$@"
	install
	msg_ok '\e[5mSuccessfully installed!\e[0m'

	if $f_install_docker || $f_install_gns3 || $f_install_virtualbox; then
		close_graphical_session
	fi
}

main "$@"

# vim: set ts=4 sw=4 noet
