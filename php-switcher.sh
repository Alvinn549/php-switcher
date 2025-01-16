#!/bin/bash

# Ensure the script is run as sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as sudo. Please rerun the script using 'sudo ./php-switcher.sh'"
    exit 1
fi

# Colors for better output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Function to print section headers
print_section() {
    echo -e "\n${CYAN}========== $1 ==========${RESET}\n"
}

# Detect installed PHP versions
get_php_versions() {
    ls /usr/bin/php* 2>/dev/null | grep -oP 'php\K[0-9]+\.[0-9]+' | sort -u
}

# Detect installed web server
detect_web_server() {
    if systemctl list-units --type=service | grep -q "nginx.service"; then
        echo "nginx"
    elif systemctl list-units --type=service | grep -q "apache2.service"; then
        echo "apache2"
    else
        echo "none"
    fi
}

# Restart detected web server
restart_web_server() {
    web_server=$(detect_web_server)
    case "$web_server" in
    nginx)
        echo -ne "${YELLOW}Restarting Nginx${RESET}..."
        sudo systemctl restart nginx &
        ;;
    apache2)
        echo -ne "${YELLOW}Restarting Apache2${RESET}..."
        sudo systemctl restart apache2 &
        ;;
    *)
        echo -e "${RED}No web server detected to restart.${RESET}"
        ;;
    esac
}

# Show current PHP version
print_section "Current PHP Version"
if command -v php >/dev/null 2>&1; then
    php -v
else
    echo -e "${RED}PHP is not installed on this system.${RESET}"
    exit 1
fi

# Get installed PHP versions
php_versions=$(get_php_versions)

# Check if any PHP versions are installed
if [ -z "$php_versions" ]; then
    echo -e "${RED}No PHP versions found on this system.${RESET}"
    exit 1
fi

# Display the menu
print_section "Installed PHP Versions"
i=1
declare -A php_map
for version in $php_versions; do
    echo -e "  ${YELLOW}[$i]${RESET} PHP ${CYAN}$version${RESET}"
    php_map[$i]=$version
    ((i++))
done

# User input
echo -ne "\n${CYAN}Select PHP version to switch to (1-$((i - 1))): ${RESET}"
read choice

# Validate input
if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ -z "${php_map[$choice]}" ]]; then
    echo -e "${RED}Invalid selection.${RESET}"
    exit 1
fi

# Selected version
selected_version=${php_map[$choice]}

php_cli_path="/usr/bin/php$selected_version"
php_fpm_sock_path="/run/php/php${selected_version}-fpm.sock"
php_cgi_path="/usr/bin/php-cgi$selected_version"
php_cgi_bin_path="/usr/lib/cgi-bin/php$selected_version"

# Switch PHP CLI
print_section "Switching PHP CLI"
if [ -f "$php_cli_path" ]; then
    if sudo update-alternatives --list php >/dev/null 2>&1; then
        echo -ne "${YELLOW}Switching PHP CLI to $selected_version...${RESET}"
        sudo update-alternatives --set php "$php_cli_path" >/dev/null &
        wait $!
        echo -e "${GREEN}[OK]${RESET}"
    else
        echo -ne "${YELLOW}Configuring PHP CLI for $selected_version...${RESET}"
        sudo update-alternatives --install /usr/bin/php php "$php_cli_path" $((selected_version * 10)) >/dev/null &
        wait $!
        sudo update-alternatives --set php "$php_cli_path" >/dev/null &
        wait $!
        echo -e "${GREEN}[OK]${RESET}"
    fi
else
    echo -e "${RED}PHP CLI $selected_version is not installed at $php_cli_path.${RESET}"
fi

# Switch PHP-FPM
print_section "Switching PHP-FPM"
if [ -S "$php_fpm_sock_path" ]; then
    if sudo update-alternatives --list php-fpm.sock >/dev/null 2>&1; then
        echo -ne "${YELLOW}Switching PHP-FPM to $selected_version...${RESET}"
        sudo update-alternatives --set php-fpm.sock "$php_fpm_sock_path" >/dev/null &
        wait $!
        echo -e "${GREEN}[OK]${RESET}"
    else
        echo -ne "${YELLOW}Configuring PHP-FPM socket for $selected_version...${RESET}"
        sudo update-alternatives --install /run/php/php-fpm.sock php-fpm.sock "$php_fpm_sock_path" $((selected_version * 10)) >/dev/null &
        wait $!
        sudo update-alternatives --set php-fpm.sock "$php_fpm_sock_path" >/dev/null &
        wait $!
        echo -e "${GREEN}[OK]${RESET}"
    fi
else
    echo -e "${RED}PHP-FPM socket for version $selected_version is not installed at $php_fpm_sock_path.${RESET}"
fi

# Switch PHP-CGI
print_section "Switching PHP-CGI"
if [ -f "$php_cgi_path" ]; then
    if sudo update-alternatives --list php-cgi >/dev/null 2>&1; then
        echo -ne "${YELLOW}Switching PHP-CGI to $selected_version...${RESET}"
        sudo update-alternatives --set php-cgi "$php_cgi_path" >/dev/null &
        wait $!
        echo -e "${GREEN}[OK]${RESET}"
    else
        echo -ne "${YELLOW}Configuring PHP-CGI for $selected_version...${RESET}"
        sudo update-alternatives --install /usr/bin/php-cgi php-cgi "$php_cgi_path" $((selected_version * 10)) >/dev/null &
        wait $!
        sudo update-alternatives --set php-cgi "$php_cgi_path" >/dev/null &
        wait $!
        echo -e "${GREEN}[OK]${RESET}"
    fi
else
    echo -e "${RED}PHP-CGI $selected_version is not installed.${RESET}"
fi

# Switch PHP-CGI-BIN
print_section "Switching PHP CGI-BIN"
if [ -f "$php_cgi_bin_path" ]; then
    if sudo update-alternatives --list php-cgi-bin >/dev/null 2>&1; then
        echo -ne "${YELLOW}Switching PHP CGI-BIN to $selected_version...${RESET}"
        sudo update-alternatives --set php-cgi-bin "$php_cgi_bin_path" >/dev/null &
        wait $!
        echo -e "${GREEN}[OK]${RESET}"
    else
        echo -ne "${YELLOW}Configuring PHP CGI-BIN for $selected_version...${RESET}"
        sudo update-alternatives --install /usr/lib/cgi-bin/php php-cgi-bin "$php_cgi_bin_path" $((selected_version * 10)) >/dev/null &
        wait $!
        sudo update-alternatives --set php-cgi-bin "$php_cgi_bin_path" >/dev/null &
        wait $!
        echo -e "${GREEN}[OK]${RESET}"
    fi
else
    echo -e "${RED}PHP CGI-BIN for version $selected_version is not installed.${RESET}"
fi

# Restart Web Server
print_section "Restarting Web Server"
restart_web_server
echo -e "${GREEN}[OK]${RESET}"

# Confirmation
print_section "PHP Version Switched"
php -v
echo -e "\n${GREEN}PHP has been switched to version $selected_version successfully!${RESET}\n"
