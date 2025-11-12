# Multi-OS Provisioning Specification

## Overview
This specification defines the requirements and implementation approach for making Comtrya manifests compatible across Linux, WSL, and macOS systems while maintaining existing functionality.

## Current State Analysis
The existing manifests are Linux/Ubuntu-specific with the following platform dependencies:
- APT package manager with PPA repositories
- Linux-specific package names and paths
- Ubuntu/Debian-specific commands and utilities
- Privileged operations using sudo/root access

## Target Platforms
1. **Linux** - Ubuntu/Debian-based distributions (current functionality)
2. **WSL** - Windows Subsystem for Linux (Windows integration)
3. **macOS** - macOS with Homebrew package management

## Architecture Requirements

### 1. Platform Detection and Variables
**Objective**: Detect the current platform and provide platform-specific variables

**Implementation Requirements:**
- Add platform detection to `Comtrya.yaml`
- Create platform-specific variable groups
- Provide conditional logic based on platform

**Required Variables:**
```yaml
variables:
  # Platform detection
  platform: "{{ os.family }}"  # linux, darwin
  is_wsl: "{{ env.WSL_DISTRO_NAME != null }}"
  is_linux: "{{ platform == 'linux' and not is_wsl }}"
  is_macos: "{{ platform == 'darwin' }}"
  
  # Package management
  package_manager: "{{ is_macos ? 'brew' : 'apt' }}"
  privileged_command: "{{ is_macos ? 'sudo' : 'sudo' }}"  # May vary by platform
  
  # Paths
  shell_path: "{{ is_macos ? '/usr/local/bin/fish' : '/usr/bin/fish' }}"
  config_base: "{{ is_macos ? '/usr/local/etc' : '/etc' }}"
```

### 2. Package Management Abstraction
**Objective**: Provide unified package installation across platforms

**Implementation Requirements:**
- Create package name mapping between platforms
- Handle different package managers (APT vs Homebrew)
- Manage repository/tap sources conditionally

**Package Mapping Requirements:**
| Linux Package | macOS Equivalent | Notes |
|---------------|------------------|-------|
| software-properties-common | N/A | macOS doesn't need this |
| build-essential | N/A | Xcode Command Line Tools |
| autoconf | autoconf | Same name |
| automake | automake | Same name |
| curl | curl | Same name |
| git | git | Same name |
| fish | fish | Same name |
| neovim | neovim | Same name |
| tmux | tmux | Same name |

### 3. Manifest-Specific Adjustments

#### 3.1 Comtrya.yaml
**Tasks:**
- Add platform detection variables
- Create platform-specific manifest includes
- Add conditional variable definitions

**Required Changes:**
```yaml
manifest_paths:
  - .
  - "{{ is_macos ? 'macos' : 'linux' }}"  # Platform-specific directories

variables:
  # Platform detection
  platform: "{{ os.family }}"
  is_wsl: "{{ env.WSL_DISTRO_NAME != null }}"
  
  # Existing variables remain unchanged
  atuin_config_path: 'https://gitea.dubas.dev/joao.dubas/ide/raw/branch/main/config/atuin/config.toml'
  # ... other existing variables
```

#### 3.2 system-deps.yml
**Tasks:**
- Replace APT-specific actions with conditional package installation
- Add Homebrew support for macOS
- Handle PPA repositories conditionally
- Create platform-specific package lists

**Required Changes:**
```yaml
actions:
  # Linux-specific PPA setup
  - action: command.run
    privileged: true
    command: add-apt-repository
    args:
      - ppa:fish-shell/release-4
    when: is_linux
    
  - action: command.run
    privileged: true
    command: add-apt-repository
    args:
      - ppa:neovim-ppa/unstable
    when: is_linux
    
  # macOS Homebrew setup
  - action: command.run
    command: brew
    args:
      - tap
      - fish-shell/fish-shell
    when: is_macos
    
  # Conditional package installation
  - action: package.install
    provider: "{{ is_macos ? 'brew' : 'apt' }}"
    list:
      # Common packages
      - curl
      - git
      - fish
      - neovim
      - tmux
      # Linux-specific packages
      - autoconf
      - build-essential
      - software-properties-common
      when: is_linux
      # macOS-specific packages
      - gcc
      when: is_macos
```

#### 3.3 system-deps/docker.yml
**Tasks:**
- Add platform-specific Docker installation methods
- Handle Docker Desktop for macOS/WSL
- Adjust group management for different platforms

**Required Changes:**
```yaml
actions:
  # Linux Docker CE installation
  - action: file.download
    from: https://get.docker.com
    to: /tmp/get-docker.sh
    chmod: '0750'
    when: is_linux
    
  - action: command.run
    privileged: true
    dir: /tmp
    command: ./get-docker.sh
    when: is_linux
    
  # macOS Docker Desktop installation
  - action: command.run
    command: brew
    args:
      - install
      - --cask
      - docker
    when: is_macos
    
  # WSL Docker Desktop setup (assumes pre-installed)
  - action: command.run
    command: echo
    args:
      - "Docker Desktop should be installed on Windows host"
    when: is_wsl
    
  # Group management (Linux only)
  - action: user.group
    username: '{{user.username}}'
    group:
      - docker
    when: is_linux
```

#### 3.4 system-deps/openssl.yml
**Tasks:**
- Make OpenSSL compilation cross-platform
- Handle different build dependencies
- Adjust compiler flags for different platforms

**Required Changes:**
```yaml
actions:
  # Install build dependencies
  - action: package.install
    provider: "{{ is_macos ? 'brew' : 'apt' }}"
    list:
      - make
      - gcc
      when: is_linux
      - make
      when: is_macos
      
  # Platform-specific compilation
  - action: command.run
    dir: '{{ user.home_dir }}/.local/src/openssl-1.1.1m'
    command: ./config
    args:
      - --prefix={{ user.home_dir }}/.local
      - --openssldir={{ user.home_dir }}/.local/ssl
    when: is_linux
    
  - action: command.run
    dir: '{{ user.home_dir }}/.local/src/openssl-1.1.1m'
    command: ./Configure
    args:
      - darwin64-x86_64-cc
      - --prefix={{ user.home_dir }}/.local
      - --openssldir={{ user.home_dir }}/.local/ssl
    when: is_macos
```

#### 3.5 CLI Tools (cli/*.yml)
**Tasks:**
- Make installation scripts cross-platform
- Handle different binary locations
- Adjust PATH modifications

**mise.yml Changes:**
```yaml
actions:
  - action: file.download
    from: https://mise.jdx.dev/install.sh
    to: /tmp/mise.sh
    chmod: '0750'
    
  - action: command.run
    dir: /tmp
    command: bash
    args:
      - -c
      - ./mise.sh
    # No platform-specific changes needed - script is cross-platform
```

#### 3.6 user/fish.yml
**Tasks:**
- Handle different Fish installation paths
- Adjust shell change commands for different platforms
- Handle WSL-specific Windows path integration

**Required Changes:**
```yaml
actions:
  # Change default shell
  - action: command.run
    privileged: true
    command: "{{ is_macos ? 'chsh' : 'usermod' }}"
    args:
      - "{{ is_macos ? '-s' : '--shell' }}"
      - "{{ shell_path }}"
      - "{{ user.username }}"
      
  # WSL-specific Windows PATH integration
  - action: command.run
    command: fish
    args:
      - -c
      - "fish_add_path -p -U -m -v /mnt/c/Windows/System32"
    when: is_wsl
    
  # macOS-specific Homebrew PATH
  - action: command.run
    command: fish
    args:
      - -c
      - "fish_add_path -p -U -m -v /opt/homebrew/bin"
    when: is_macos
```

#### 3.7 user/neovim.yml
**Tasks:**
- Handle different Neovim installation methods
- Adjust for different clipboard behaviors
- Handle font and rendering differences

**Required Changes:**
```yaml
actions:
  # Install Neovim if not present
  - action: package.install
    provider: "{{ is_macos ? 'brew' : 'apt' }}"
    name: neovim
    when: >
      (is_macos and not command_exists('nvim')) or 
      (is_linux and not command_exists('nvim'))
      
  # Rest of manifest remains largely unchanged
  # Git operations are cross-platform
```

#### 3.8 user/git.yml
**Tasks:**
- Handle different credential managers
- Adjust for different SSH key locations
- Handle WSL-specific Git configurations

**Required Changes:**
```yaml
actions:
  # Platform-specific credential helper configuration
  - action: command.run
    command: git
    args:
      - config
      - --global
      - credential.helper
      - "{{ is_macos ? 'osxkeychain' : (is_wsl ? '/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe' : 'libsecret') }}"
      
  # SSH key path adjustments
  - action: command.run
    command: fish
    args:
      - -c
      - "set -Ux SSH_KEY_HOME {{ is_wsl ? '/mnt/c/Users/' + user.username + '/.ssh' : user.home_dir + '/.ssh' }}"
    when: is_wsl
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
1. Update `Comtrya.yaml` with platform detection
2. Create platform-specific variable definitions
3. Implement basic conditional logic patterns

### Phase 2: Package Management (Week 2)
1. Refactor `system-deps.yml` with conditional package installation
2. Create package name mappings
3. Implement Homebrew support for macOS

### Phase 3: System Services (Week 3)
1. Update Docker installation for multi-platform support
2. Refactor OpenSSL compilation
3. Handle platform-specific service configurations

### Phase 4: User Configuration (Week 4)
1. Update Fish shell configuration
2. Refactor Git configuration
3. Handle Neovim cross-platform setup

### Phase 5: CLI Tools (Week 5)
1. Update CLI tool installations
2. Handle platform-specific binary locations
3. Test PATH configurations

### Phase 6: Testing and Validation (Week 6)
1. Test on all target platforms
2. Validate configurations
3. Documentation updates

## Conditional Logic Patterns

### Package Installation Pattern
```yaml
- action: package.install
  provider: "{{ is_macos ? 'brew' : 'apt' }}"
  name: "{{ is_macos ? 'package-name-macos' : 'package-name-linux' }}"
  when: is_macos or is_linux
```

### Command Execution Pattern
```yaml
- action: command.run
  command: "{{ is_macos ? 'brew' : 'apt-get' }}"
  args: ["install", "package-name"]
  when: is_macos or is_linux
```

### File Path Pattern
```yaml
- action: file.copy
  from: config-file
  to: "{{ is_macos ? '/usr/local/etc' : '/etc' }}/config-file"
```

### Platform-Specific Actions Pattern
```yaml
# Linux-specific action
- action: command.run
  command: apt-get
  args: ["update"]
  when: is_linux
  
# macOS-specific action  
- action: command.run
  command: brew
  args: ["update"]
  when: is_macos
  
# WSL-specific action
- action: command.run
  command: echo
  args: ["WSL-specific setup"]
  when: is_wsl
```

## Testing Requirements

### Platform Testing Matrix
| Component | Linux | WSL | macOS | Notes |
|-----------|-------|-----|-------|-------|
| Package Installation | ✅ | ✅ | ✅ | Different package managers |
| Shell Configuration | ✅ | ✅ | ✅ | Different shell paths |
| Docker Setup | ✅ | ✅ | ✅ | Different installation methods |
| Git Configuration | ✅ | ✅ | ✅ | Different credential helpers |
| Neovim Setup | ✅ | ✅ | ✅ | Cross-platform compatible |
| CLI Tools | ✅ | ✅ | ✅ | Installation script variations |

### Validation Criteria
1. **Package Installation**: All required packages install successfully
2. **Configuration Application**: All configurations apply correctly
3. **Tool Functionality**: All tools work as expected after installation
4. **Path Resolution**: All paths resolve correctly on each platform
5. **Permission Handling**: Privileged operations work correctly

## Migration Strategy

### Backward Compatibility
- Maintain existing Linux functionality
- Ensure current manifests continue to work without modification
- Provide gradual migration path

### Rollout Plan
1. **Parallel Development**: Create new platform-specific manifests alongside existing ones
2. **Feature Flags**: Use conditional logic to enable platform-specific features
3. **Gradual Migration**: Migrate users incrementally with clear documentation
4. **Deprecation**: Phase out Linux-only manifests after validation

## Documentation Requirements

### User Documentation
- Platform-specific installation instructions
- Feature compatibility matrix
- Troubleshooting guides for each platform
- Migration instructions for existing users

### Developer Documentation
- Platform detection implementation details
- Conditional logic patterns and examples
- Testing procedures for multi-platform support
- Contribution guidelines for platform-specific features

## Success Metrics

### Technical Metrics
- 100% package installation success rate across all platforms
- 95%+ configuration application success rate
- Zero regression in existing Linux functionality

### User Experience Metrics
- Consistent user experience across platforms
- Minimal platform-specific user intervention required
- Clear error messages and troubleshooting guidance

## Risk Mitigation

### Technical Risks
- **Package Name Conflicts**: Maintain comprehensive package mapping
- **Path Differences**: Use platform variables consistently
- **Permission Issues**: Handle privileged operations appropriately

### Operational Risks
- **Testing Coverage**: Implement comprehensive testing matrix
- **Documentation Gaps**: Provide detailed platform-specific guides
- **User Confusion**: Clear migration path and support

## Future Considerations

### Additional Platforms
- Windows (native) support
- Other Linux distributions (Fedora, Arch)
- Container-based deployments

### Enhancement Opportunities
- Automatic platform detection improvements
- Dynamic package repository configuration
- Cross-platform configuration synchronization