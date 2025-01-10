# PHP Version Switcher Script

This script allows you to switch between different installed PHP versions on your Debian-based Linux system (e.g., Debian, Ubuntu).

With this script, you can easily:

- Switch between different PHP CLI versions.
- Switch PHP-FPM socket to the selected version.
- Switch PHP-CGI and PHP CGI-BIN for web applications.
- Automatically restart the web server (`nginx` or `apache2`) after switching PHP versions.

## Installation

   ```bash
    git clone https://github.com/Alvinn549/bengkel-cat-w.git

    cd bengkel-cat-w

    chmod +x switch_php_version.sh

    ./switch_php_version.sh
