#!/bin/bash

# Ensure the script is run as sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as sudo. Please rerun the script using 'sudo ./setup.sh'"
    exit 1
fi

# Colors for better output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Available PHP versions
AVAILABLE_PHP_VERSIONS=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3" "8.4")

# PHP extensions to install
PHP_EXTENSIONS=("cli" "mysql" "imap" "intl" "apcu" "cgi" "bz2" "zip" "mbstring" "gd" "curl" "xml" "common" "opcache" "imagick")

# Function to print section headers
print_section() {
    echo -e "\n${CYAN}========== $1 ==========${RESET}\n"
}

# Spinner function for loading effect
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\\'
    while ps -p $pid >/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Detect installed PHP versions
get_installed_php_version() {
    ls /usr/bin/php* 2>/dev/null | grep -oP 'php\K[0-9]+\.[0-9]+' | sort -u
}

# Detect distro name
get_distro_name() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        echo "unknown"
    fi
}

# Restrict script to Debian and Ubuntu
check_supported_distro() {
    distro=$(get_distro_name)
    if [[ "$distro" == "debian" || "$distro" == "ubuntu" ]]; then
        echo -e "${GREEN}Detected supported OS: $distro${RESET}"
    else
        echo -e "${RED}This script only supports Debian and Ubuntu.${RESET}"
        exit 1
    fi
}

# Check if repository is already added
is_repo_installed() {
    local repo=$1
    grep -i "$repo" /etc/apt/sources.list /etc/apt/sources.list.d/* >/dev/null
}

# Function to check if a web server is installed
check_web_server() {
    if command -v apache2 >/dev/null 2>&1; then
        echo -e "${GREEN}Apache is already installed.${RESET}"
    elif command -v nginx >/dev/null 2>&1; then
        echo -e "${GREEN}Nginx is already installed.${RESET}"
    else
        echo -e "${YELLOW}No web server detected.${RESET}"
        echo -e "${CYAN}Select a web server to install:${RESET}"
        echo "1) Apache"
        echo "2) Nginx"
        read -p "Enter your choice [1/2]: " web_choice

        case "$web_choice" in
        1)
            echo -e "${GREEN}Installing Apache...${RESET}"
            sudo apt install -y apache2 >/dev/null 2>&1 &
            show_spinner $!
            echo -e "${GREEN}Apache installation completed.${RESET}"
            ;;
        2)
            echo -e "${GREEN}Installing Nginx...${RESET}"
            sudo apt install -y nginx >/dev/null 2>&1 &
            show_spinner $!
            echo -e "${GREEN}Nginx installation completed.${RESET}"
            ;;
        *)
            echo -e "${RED}Invalid choice. Skipping web server installation.${RESET}"
            ;;
        esac
    fi
}

# Set up PHP repository based on distro
setup_php_repo() {
    distro=$(get_distro_name)
    print_section "Checking PHP Repository for $distro"

    if [[ "$distro" == "debian" ]]; then
        if is_repo_installed "packages.sury.org/php"; then
            echo -e "${YELLOW}PHP repository for Debian is already installed.${RESET}"
        else
            echo -e "${GREEN}Installing PHP repository for Debian...${RESET}"
            (sudo apt-get update -y >/dev/null && sudo apt install lsb-release apt-transport-https ca-certificates wget gnupg -y >/dev/null && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg >/dev/null && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list >/dev/null && sudo apt-get update -y >/dev/null) &
            spinner
            echo -e "${GREEN}PHP repository for Debian has been set up successfully.${RESET}"
        fi

    elif [[ "$distro" == "ubuntu" ]]; then
        if is_repo_installed "ppa.launchpad.net/ondrej/php"; then
            echo -e "${YELLOW}PHP repository for Ubuntu is already installed.${RESET}"
        else
            echo -e "${GREEN}Installing PHP repository for Ubuntu...${RESET}"
            (sudo apt-get update -y >/dev/null && sudo apt install software-properties-common gnupg2 -y >/dev/null && sudo add-apt-repository -y ppa:ondrej/php >/dev/null && sudo apt-get update -y >/dev/null) &
            spinner
            echo -e "${GREEN}PHP repository for Ubuntu has been set up successfully.${RESET}"
        fi
    fi
}

# Display available PHP versions with installation status
show_php_versions_menu() {
    print_section "Available PHP Versions"

    local installed_versions=($(get_installed_php_version))

    echo -e "${YELLOW}Select PHP versions to install:${RESET}"

    for i in "${!AVAILABLE_PHP_VERSIONS[@]}"; do
        version="${AVAILABLE_PHP_VERSIONS[$i]}"
        if [[ " ${installed_versions[*]} " =~ " ${version} " ]]; then
            echo -e "$((i + 1)). PHP $version ${GREEN}(Installed)${RESET}"
        else
            echo -e "$((i + 1)). PHP $version"
        fi
    done

    echo -e "$((${#AVAILABLE_PHP_VERSIONS[@]} + 1)). ${CYAN}All Versions${RESET}"
}

# Handle user selection
process_php_selection() {
    read -p "Enter your choice (e.g., 1,3,5): " user_choice

    if [[ "$user_choice" == "12" ]]; then
        selected_versions=("${AVAILABLE_PHP_VERSIONS[@]}")
    else
        IFS=',' read -ra choices <<<"$user_choice"
        selected_versions=()
        for choice in "${choices[@]}"; do
            index=$((choice - 1))
            if [[ $index -ge 0 && $index -lt ${#AVAILABLE_PHP_VERSIONS[@]} ]]; then
                selected_versions+=("${AVAILABLE_PHP_VERSIONS[$index]}")
            else
                echo -e "${RED}Invalid selection: $choice${RESET}"
            fi
        done
    fi
}

# Install selected PHP versions and extensions with spinner
install_php_versions() {
    print_section "Installing Selected PHP Versions"

    LOG_FILE="php_install_errors.log"
    : >"$LOG_FILE" # Clear the log file before starting

    for version in "${selected_versions[@]}"; do
        package_list=("php$version" "php$version-fpm")
        for ext in "${PHP_EXTENSIONS[@]}"; do
            package_list+=("php$version-$ext")
        done

        echo -ne "${YELLOW}Installing PHP $version...${RESET}"

        # Install packages and log errors if any
        (sudo apt-get install -y "${package_list[@]}" >/dev/null 2>>"$LOG_FILE") &
        spinner

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[OK]${RESET}"
        else
            echo -e "${RED}[FAILED]${RESET}"
            echo "[$(date)] Installation failed for PHP $version. Check $LOG_FILE for details." >>"$LOG_FILE"
        fi
    done

    # Notify if there were errors
    if [[ -s "$LOG_FILE" ]]; then
        echo -e "\n${RED}Some installations failed. Check the log file for details: ${YELLOW}$LOG_FILE${RESET}\n"
    fi
}

# Restrict to Debian/Ubuntu
print_section "Checking Supported OS"
check_supported_distro

# Call the function after checking supported distro
print_section "Checking Web Server Installation"
check_web_server

# Set up PHP repository
setup_php_repo

# Show available PHP versions and handle user input
show_php_versions_menu
process_php_selection

# Install selected PHP versions with extensions
install_php_versions

echo -ne "\n"
echo -e "${GREEN}PHP installation process completed.${RESET}"

# Show current PHP version
print_section "Current PHP Version"
if command -v php >/dev/null 2>&1; then
    php -v
else
    echo -e "${RED}PHP is failed to install on this system.${RESET}"
    exit 1
fi

echo -ne "\n"
echo -e "${YELLOW}To switch between installed PHP versions, run:${RESET} ${CYAN}sudo ./php-switcher.sh${RESET}\n"
