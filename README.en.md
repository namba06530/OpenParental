# OpenParental

![MIT License](https://img.shields.io/badge/license-MIT-green.svg)

OpenParental is an open source parental control solution for Ubuntu. It provides easy deployment and robust features for families, schools, and public spaces: screen time management, web filtering, Internet quotas, and more.

## 🚀 Why OpenParental?
- **Open Source**: 100% free, transparent, and customizable.
- **Simple**: Automated installation scripts, no proprietary lock-in.
- **Secure**: Strict account separation, multi-layer filtering, secure SSH setup.
- **Community-Driven**: Contributions welcome to improve digital safety for all.

## 📁 Project Structure
// ...existing code...

## 🎯 Project Goals
// ...existing code...

## 🛠 Solution Components
// ...existing code...

## 📋 Requirements
// ...existing code...

## 🚀 Standard Installation (family, school, public space...)

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/OpenParental.git
   cd OpenParental
   ```
2. **Customize the** `.env` **file** (a ready-to-use example is provided as `.env.example`)
3. **Run the full installation**
   ```bash
   sudo ./00-install.sh
   ```

That's it! The 00-install.sh script handles everything: account creation, network setup, filtering, quotas, antivirus, final security, and more.

> **Tip**: This method works for a single family computer or a fleet of devices in schools or public spaces.

## 🚚 Deploying on Child Devices

> **Note**: For most use cases, simply follow the standard installation procedure above on each device to be protected. The 00-install.sh script automatically configures Internet quota management, filtering, security, etc.

If you want to deploy **only the Internet quota management** on an existing device (advanced use):

1. Clone the repository and adapt the .env
2. Run only:
   ```bash
   sudo ./06-set-internet-quota.sh
   ```

## 📝 Roadmap
// ...existing code...

## 🔒 Security & Privacy
- No data sent outside the device by default.
- Logs and quotas remain local.
- Parents remain responsible for supervision.

## 📚 Detailed Documentation
// ...existing code...

## 🤝 Contributing

Contributions are **welcome**!

- Fork the project
- Create a branch (`git checkout -b feature/my-feature`)
- Commit your changes (`git commit -am 'Add my feature'`)
- Push the branch (`git push origin feature/my-feature`)
- Open a Pull Request

For questions, suggestions, or bugs, open an [issue](https://github.com/your-username/OpenParental/issues) or join the discussions.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file.

## ⚠️ Disclaimer & Ethics

This project is provided "as is", without warranty. It aims to help families and organizations manage digital usage responsibly and ethically. **Never use this project to monitor or restrict others without consent.**

---

> _Made with ❤️ by the open source community. Join us to improve digital safety for families and schools!_