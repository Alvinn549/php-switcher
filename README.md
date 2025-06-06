
# PHP Version Switcher

1. Install a web server.
2. Install multiple PHP versions.
2. Switch between different installed PHP versions seamlessly.

## Features

- Install and configure a web server `Apache` or `Nginx`.
- Install multiple PHP versions, including `5.6`, `7.0`, `7.1`, `7.2`, `7.3`, `7.4`, `8.0`, `8.1`, `8.2`, `8.3`, `8.4`.
- Switch between different PHP CLI versions.
- Update the PHP-FPM socket to the selected PHP version.
- Adjust PHP-CGI and PHP CGI-BIN configurations for web applications.

## Supported Operating Systems

- Debian
- Ubuntu

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Alvinn549/php-switcher.git
   ```

2. Navigate to the directory:

   ```bash
   cd php-switcher
   ```

3. Make the setup and switcher scripts executable:

   ```bash
   chmod +x setup.sh php-switcher.sh
   ```

4. Run the setup script to install and configure the web server and php:

   ```bash
   sudo ./setup.sh
   ```

5. Use the PHP switcher script to change PHP versions:

   ```bash
   sudo ./php-switcher.sh
   ```

## License

This project is licensed under the MIT License.
