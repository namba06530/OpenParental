# TODO - Internet Quota System

## Task Format
```
[TASK-ID]: TITLE
- priority: PRIORITY (1-5, where 1 is highest)
- phase: PHASE
- status: STATUS (todo|in_progress|done)
- depends_on: [ID1, ID2]
- assignee: NAME (optional)
- estimate: ESTIMATE (optional, in hours)
- labels: [label1, label2]
- description: |
    Detailed description of the task that will be used
    to automatically generate a GitHub issue.
    Should include:
    - Context
    - Objectives
    - Acceptance criteria
    - Resources or useful references
```

## 🎯 Objective
Improve the security, reliability, and functionality of the Internet quota management system.

## 📋 Tasks by Phase

### ✅ Phase 1, 2, 3 - Completed Tasks
- [x] Analysis of current system
- [x] Simplified and stable script version
- [x] Advanced logging system
- [x] Robust error handling
- [x] Basic unit tests
- [x] Systemd integration

### 🔄 Phase 4 - Modularization (IN PROGRESS)

#### High Priority
- [x] A1. Code Modularization
  - **Description**: Separation into modules (quota-core.sh, quota-security.sh, quota-network.sh, quota-config.sh)
  - **Status**: Completed
  - **Dependencies**: None

- [ ] A3. Integration Tests
  - **Description**: Tests between different modules
  - **Status**: To do
  - **Dependencies**: A1

#### Medium Priority
- [ ] A4. API Documentation
  - **Description**: Detailed API documentation for each module
  - **Status**: To do
  - **Dependencies**: A1

### 🔒 Phase 5 - Security

#### High Priority
- [ ] S1. Data Protection
  - **Description**: Encryption of quota files
  - **Status**: To do
  - **Dependencies**: A1

- [ ] S2. Bypass Detection
  - **Description**: Detection of manipulation attempts
  - **Status**: To do
  - **Dependencies**: S1

- [ ] S3. Integrity Verification
  - **Description**: Checksum system
  - **Status**: To do
  - **Dependencies**: S1

#### Medium Priority
- [ ] S4. Security Logging
  - **Description**: Logging of security events
  - **Status**: To do
  - **Dependencies**: S1, S2

### 🔄 Phase 6 - Detection and Backup

#### High Priority
- [ ] F4. Precise Detection
  - **Description**: Internet activity detection system
  - **Status**: To do
  - **Dependencies**: A1

#### Medium Priority
- [ ] F1. Backup System
  - **Description**: Automatic data backup
  - **Status**: To do
  - **Dependencies**: S1

### 💾 Phase 7 - Database

#### High Priority
- [ ] A2. SQLite Migration
  - **Description**: Migration to SQLite
  - **Status**: To do
  - **Dependencies**: A1

#### Medium Priority
- [ ] F2. Transaction Management
  - **Description**: Concurrency management
  - **Status**: To do
  - **Dependencies**: A2

### 🎨 Phase 8 - User Interface

#### High Priority
- [ ] U1. Notifications
  - **Description**: Improved notification system
  - **Status**: To do
  - **Dependencies**: A1

#### Medium Priority
- [ ] U2. Web Interface
  - **Description**: Simple web interface
  - **Status**: To do
  - **Dependencies**: A2

### 🚀 Phase 9 - Advanced Features

#### High Priority
- [ ] F5. Application-specific Quotas
  - **Description**: Management of quotas by application
  - **Status**: To do
  - **Dependencies**: A1, A2

- [ ] F6. Exception Management
  - **Description**: Bonus time and exceptions system
  - **Status**: To do
  - **Dependencies**: A1

#### Medium Priority
- [ ] F7. REST API
  - **Description**: API for external integration
  - **Status**: To do
  - **Dependencies**: A2

#### Low Priority
- [ ] U3. Dashboard
  - **Description**: Advanced dashboard with statistics
  - **Status**: To do
  - **Dependencies**: U2

- [ ] F3. Auto-Recovery
  - **Description**: Automatic recovery system
  - **Status**: To do
  - **Dependencies**: F1, F2

## Active Tasks

### A3: Integration Tests Between Modules
- priority: 1
- phase: 4
- status: todo
- depends_on: [A1]
- labels: [test, core, integration]
- description: |
    Develop a comprehensive integration test suite to verify the interactions between the different quota system modules.
    
    **Context**: The modules (quota-core.sh, quota-security.sh, quota-network.sh, quota-config.sh, quota-logging.sh) have been developed and work individually, but their integration needs to be verified.
    
    **Objectives**:
    - Create automated tests for all integrations between modules
    - Verify edge cases and error conditions
    - Ensure modules work together as expected
    
    **Acceptance criteria**:
    - Tests executable in Docker
    - Coverage of at least 85% of interactions between modules
    - Documentation of tests in the `tests/integration/` folder
    - All tests pass without errors
    
    **Resources**:
    - See existing modules in `src/modules/`
    - Reference of current unit tests in `tests/`

### S1: Data Protection with Encryption
- priority: 1
- phase: 5
- status: todo
- depends_on: [A1]
- labels: [security, encryption]
- description: |
    Implement an encryption system to protect quota data files from unauthorized access.
    
    **Context**: Quota data is currently stored in plain text, which presents a potential security risk if a user accesses the files.
    
    **Objectives**:
    - Encrypt quota data files
    - Implement a secure key management mechanism
    - Maintain system performance
    
    **Acceptance criteria**:
    - Use of standard encryption algorithms (AES-256)
    - Transparent integration with existing modules
    - Security tests validating protection
    - Complete documentation of implementation
    
    **Resources**:
    - See `quota-security.sh` for integration
    - OpenSSL for encryption operations

### S2: System Bypass Detection
- priority: 1
- phase: 5
- status: todo
- depends_on: [S1]
- labels: [security, monitoring]
- description: |
    Develop a system capable of detecting attempts to bypass Internet quotas.
    
    **Context**: Advanced users may try to bypass the quota system through various methods.
    
    **Objectives**:
    - Detect unauthorized modifications to files
    - Monitor attempts to manipulate iptables rules
    - Identify known bypass methods
    
    **Acceptance criteria**:
    - Real-time detection of manipulations
    - Detailed logging of attempts
    - Administrator alerts
    - Self-repair mechanisms if possible
    
    **Resources**:
    - Documentation on iptables
    - Existing quota-security.sh module

### F4: Precise Internet Activity Detection
- priority: 1
- phase: 6
- status: todo
- depends_on: [A1]
- labels: [feature, monitoring]
- description: |
    Create a precise Internet activity detection system to effectively track usage time.
    
    **Context**: The current system may not detect certain forms of Internet usage or incorrectly account for idle time.
    
    **Objectives**:
    - Implement precise active network activity detection
    - Distinguish active browsing from passive usage
    - Implement intelligent inactivity timer
    
    **Acceptance criteria**:
    - Accurate measurement of active usage time
    - Reduction of false positives and negatives
    - Documented tests with various use cases
    - Minimal performance impact on the system
    
    **Resources**:
    - quota-network.sh module
    - Tools like nethogs, iptraf

### A2: Migration to SQLite
- priority: 1
- phase: 7
- status: todo
- depends_on: [A1]
- labels: [database, core]
- description: |
    Migrate quota data storage to an SQLite database to improve reliability and performance.
    
    **Context**: Currently, data is stored in text files, which limits query capabilities and transaction management.
    
    **Objectives**:
    - Create an SQLite database schema
    - Migrate existing functionality
    - Ensure backward compatibility
    
    **Acceptance criteria**:
    - Documented database schema
    - Migration without data loss
    - Complete unit tests
    - Performance equal to or better than current system
    
    **Resources**:
    - SQLite documentation
    - Existing quota-core.sh module

### A4: Module API Documentation
- priority: 2
- phase: 4
- status: todo
- depends_on: [A1]
- labels: [documentation]
- description: |
    Create comprehensive API documentation for each system module.
    
    **Context**: Modules work but lack standardized documentation to facilitate their use and maintenance.
    
    **Objectives**:
    - Document each exported function from the modules
    - Describe parameters, return values, and behaviors
    - Provide usage examples
    
    **Acceptance criteria**:
    - Markdown documentation in `docs/api/`
    - Functional examples for each function
    - Documentation of error behaviors
    - Clear and consistent organization
    
    **Resources**:
    - Modules in src/modules/
    - Examples of existing documentation

## Completed Tasks

### A1: Code Modularization
- priority: 1
- phase: 4
- status: done
- labels: [architecture, refactoring]
- description: |
    Separation of code into independent modules with well-defined responsibilities.
    
    Modules created:
    - quota-core.sh: Basic quota management functionality
    - quota-security.sh: Data protection and verification
    - quota-network.sh: Firewall rule management
    - quota-config.sh: Configuration management
    - quota-logging.sh: Logging system 