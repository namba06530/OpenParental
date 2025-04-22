# OpenParental – HandMade Parental Control Stack for Ubuntu

![MIT License](https://img.shields.io/badge/license-MIT-green.svg)

A complete **open source** parental control solution for Ubuntu, designed to be simple, robust, and accessible to all. This project aims to provide families with effective control over screen time and Internet access, while respecting privacy and the philosophy of free software.

## 🚀 Why this project?
- **Freedom**: 100% open source, modifiable and shareable.
- **Simplicity**: Guided installation via scripts, no dependency on proprietary solutions.
- **Security**: Strict account separation, multi-layer filtering, secure SSH configuration.
- **Community**: Open to contributions, to improve digital protection for families together.

## 📁 Project Structure

```
OpenParental/
├── src/                                # Source code
│   ├── internet-quota.sh              # Main quota management script
│   └── lib/
│       └── logging.sh                 # Logging library
├── tests/                             # Test suite
│   ├── test-logging.sh               # Logging tests
│   └── test-iptables.sh              # Iptables tests
├── docs/                              # Documentation
│   ├── README.md                     # English documentation
│   └── README.fr.md                  # French documentation
└── ...
```

## 🎯 Project Goals

- Provide robust and customizable parental control
- Simplify deployment and configuration
- Enable effective monitoring and management of screen and Internet time
- Protect children from inappropriate online content

## 🛠 Solution Components

### 1. Account Management
- Creation of a hidden admin account
- Separation of privileges between admin and users
- Protection of access to system settings

### 2. Secure Remote Access
- SSH configuration for remote administration
- Securing access
- Remote monitoring

### 3. DNS Filtering
- Automatic configuration of Cloudflare Family DNS (1.1.1.3 and 1.0.0.3)
- Blocking of malicious and adult content
- Protection against DNS settings modification

### 4. Web Filtering with hBlock
- Advanced blocking of ads, trackers, and malicious content
- Automatic update of blocklists
- Additional protection via the system hosts file

### 5. Screen Time Control (Timekpr-nExT)
- Limiting computer usage time
- Defining allowed time slots
- Detailed usage tracking

### 6. Internet Connection Management (Quota)
- Limiting Internet connection time
- Customizable quota system
- Usage monitoring
- Dedicated script to deploy on each child machine

### 7. Logging System
- Comprehensive logging with multiple levels (DEBUG, INFO, WARN, ERROR, SECURITY)
- Automatic log rotation and cleanup
- Detailed tracking of system events and user actions
- Secure storage of logs with proper permissions

## 📋 Prerequisites

- Ubuntu (recommended version: 22.04 LTS or higher)
- A user account with sudo rights for initial installation
- NetworkManager
- Internet connection to install components
- iptables for network filtering

## 🚀 Standard Installation (family, school, association...)

1. **Clone the repository**
   ```bash
   git clone https://github.com/namba06530/OpenParental.git
   cd OpenParental
   ```
2. **Customize the** `.env` **file** (a ready-to-use example is provided as `.env.example`)
3. **Run the full installation**
   ```bash
   sudo ./00-install.sh
   ```

That's it! The 00-install.sh script takes care of everything: account creation, network configuration, filtering, quotas, antivirus, final hardening, etc.

> **Tip**: This method works for both a family computer and a fleet of computers in a school or public place.

## 🚚 Deployment on Child Machines

> **Note**: For most use cases, simply follow the standard installation procedure above on each machine to be protected. The 00-install.sh script automatically configures Internet quota management, filtering, security, etc.

If you want to deploy **only the Internet quota management** on an existing machine (advanced use case):

1. Clone the repository and adapt the .env
2. Run only:
   ```bash
   sudo ./06-set-internet-quota.sh
   ```

## 📝 Roadmap

- [x] Installation scripts (account creation, filtering, quotas, etc.)
- [x] Unified installation script (00-install.sh, single entry point)
- [x] Internet Quota feature (Internet quota management)
- [x] Logging system implementation
- [x] Automated testing framework
- [ ] Separation of Internet time and screen time (priority)
- [ ] Improved multi-user management for Internet quota and screen time
- [ ] Graphical administration interface
- [ ] Reporting and statistics system
- [ ] Backup and restore configurations
- [ ] Remote web administration interface
- [ ] Automatic component updates
- [ ] Notification system for parents
- [ ] Enhanced multi-user support
- [ ] Detailed configuration documentation
- [ ] First-time setup assistant

> 💡 The separation of Internet time and screen time is now the project's top priority. Feel free to suggest new ideas or contribute to the roadmap!

## 🔒 Security & Privacy
- No data sent outside the machine by default.
- Logs and quotas remain local.
- Parents remain responsible for supervision.
- Encrypted storage of sensitive data.
- Regular security audits and updates.

## 📚 Detailed Documentation

### Admin Account
- Creation of a hidden admin account
- Sudo rights configuration
- Login interface protection

### SSH Configuration
- Secure installation
- Key and access configuration
- Recommended security settings

### DNS Configuration
The `03-force-custom-dns.sh` script:
- Configures NetworkManager to ignore DHCP DNS
- Uses Cloudflare Family DNS for filtering
- Protects the configuration from changes

### Time Management
Timekpr-nExT allows:
- Setting daily limits
- Configuring allowed time slots
- Managing multiple user accounts

### Internet Quota
The `src/internet-quota.sh` script manages:
- Limiting connection time
- Usage tracking
- Custom quota rules
- Notifications and whitelist management
- Simple and efficient logging of usage data

### Logging System
The `src/lib/logging.sh` library provides:
- Multiple log levels (DEBUG, INFO, WARN, ERROR, SECURITY)
- Automatic log rotation
- Secure storage of logs
- Detailed event tracking
- Performance monitoring

### Filtering with hBlock
hBlock allows:
- Blocking ads and trackers
- Protection against malicious domains
- Regular update of blocklists
- Customization of whitelists/blacklists

## 🔒 Final Hardening: Automatic Removal of Scripts and .env File

At the very end of the installation, when running the `99-final-script.sh` script, a hardening phase is offered:

- **Automatic removal of all installation scripts** (`00-*.sh` to `99-*.sh`)
- **Removal of the `.env` file** (containing sensitive parameters)

This step strengthens security by removing anything that could allow reconfiguration or bypassing protection after installation.

> You can choose to accept or refuse this removal when running the script. If you refuse, remember to manually delete these files for optimal security.

## 🤝 Contributing

Contributions are **welcome**!

- Fork the project
- Create a branch (`git checkout -b feature/my-feature`)
- Commit your changes (`git commit -am 'Add my feature'`)
- Push the branch (`git push origin feature/my-feature`)
- Open a Pull Request

For any questions, suggestions, or bugs, open an [issue](https://github.com/your-username/OpenParental/issues) or join the discussions.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file.

## ⚠️ Disclaimer & Ethics

This project is provided "as is", without warranty. It aims to help families better manage digital usage, respecting privacy and ethics. **Never use this project to monitor or restrict others without consent.**

---

> _Made with ❤️ by the open source community. Join us to improve digital safety for families!_

## Tests

The project includes several test suites to ensure system quality and reliability:

### Logging Tests

The logging tests are organized into three distinct categories:

1. **Logging Infrastructure Tests** (`test-logging.sh`)
   - Verifies basic logging system functionality
   - Tests log file creation, rotation, and cleanup
   - Ensures logging infrastructure works correctly

2. **Error Handling Tests** (`test-error-handling-module.sh`)
   - Verifies error formatting and handling
   - Tests integration between logging system and error handling
   - Ensures error messages are properly formatted and recorded

3. **Log Usage Tests**
   - Verifies log usage in specific contexts
   - Tests log integration with other features
   - Ensures logs are properly used across different modules

All tests are executed in isolated Docker containers to ensure security and reproducibility.

## 🔧 Internet Quota Module

A modular internet quota system has been integrated into the project to allow precise control over users' Internet connection time. This system is designed to be:
- **Modular**: Split into independent, reusable components
- **Secure**: Built with security-first approach
- **Reliable**: Robust error handling and logging
- **Maintainable**: Clear separation of concerns

### Module Architecture

```
src/modules/
├── quota-core.sh      # Core quota management
├── quota-security.sh  # Security and file operations
├── quota-network.sh   # Network and firewall rules
├── quota-config.sh    # Configuration management
└── quota-logging.sh   # Logging system
```

### Key Features

#### Core Module (quota-core.sh)
- Quota tracking and management
- Time increment and reset functions
- Status reporting
- Concurrency handling with locks

#### Security Module (quota-security.sh)
- Secure file operations
- Permission management
- Access control
- File integrity checks

#### Network Module (quota-network.sh)
- iptables rule management
- Whitelist system
- User-based network control
- Cleanup utilities

#### Config Module (quota-config.sh)
- Centralized configuration
- Parameter validation
- Config file management
- Default settings

#### Logging Module (quota-logging.sh)
- Multi-level logging (DEBUG, INFO, WARN, ERROR)
- Log rotation and cleanup
- Standardized message formatting
- Performance monitoring

### Usage Examples

1. **Check Current Quota Status**
   ```bash
   internet-quota status
   ```

2. **Increment Usage Time**
   ```bash
   internet-quota increment 30  # Add 30 minutes
   ```

3. **Reset Daily Quota**
   ```bash
   internet-quota reset
   ```

4. **Configure Settings**
   ```bash
   internet-quota config quota=120  # Set daily quota to 120 minutes
   ```

### Integration

The quota system integrates with:
- System logging for monitoring
- iptables for network control
- systemd for automation
- User notification system

### Security Features

- File permission controls
- Process isolation
- Secure configuration storage
- Activity logging
- Network rule protection

### Future Enhancements

- Data encryption
- Advanced bypass detection
- Per-application quotas
- Web interface
- Detailed statistics

For more details, see the [TODO.md](docs/TODO.md) file.