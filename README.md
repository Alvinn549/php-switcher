# PHP Version Switcher

Easily manage and switch between multiple PHP versions on your Debian or Ubuntu server. This tool automates the installation, configuration, and switching of PHP versions for both CLI and web server environments (Apache or Nginx).

---

## Features

- Install and configure a web server (`Apache` or `Nginx`).
- Install multiple PHP versions: `5.6`, `7.0`, `7.1`, `7.2`, `7.3`, `7.4`, `8.0`, `8.1`, `8.2`, `8.3`, `8.4`.
- Seamlessly switch between different PHP CLI versions.
- Update the PHP-FPM socket to the selected PHP version.
- Adjust PHP-CGI and CGI-BIN configurations for web applications.

## Prerequisites

- Supported OS: **Debian** or **Ubuntu**
- Root or sudo privileges

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Alvinn549/php-switcher.git
   ```

2. **Navigate to the directory:**

   ```bash
   cd php-switcher
   ```

3. **Make the setup and switcher scripts executable:**

   ```bash
   chmod +x setup.sh php-switcher.sh
   ```

4. **Run the setup script to install and configure the web server and PHP:**

   ```bash
   sudo ./setup.sh
   ```

5. **Switch PHP versions using the switcher script:**

   ```bash
   sudo ./php-switcher.sh
   ```

## Usage Example

After running the switcher script, follow the on-screen prompts to select your desired PHP version. The script will automatically update the CLI, FPM, and web server configurations.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for improvements or bug fixes.

## License

This project is licensed under the MIT License.
