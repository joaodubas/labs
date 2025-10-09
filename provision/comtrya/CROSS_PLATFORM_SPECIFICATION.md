# Cross-Platform Comtrya Manifests Specification

## Overview
This specification outlines the necessary adjustments to make the current Comtrya manifests compatible across Linux, WSL, and macOS systems while maintaining existing functionality.

## Current Platform Dependencies
The current manifests are Linux/Ubuntu-specific with the following platform-specific elements:
- APT package manager
- PPA repositories
- Linux-specific package names
- Linux file paths and commands
- Privileged commands using sudo/root

## Required Adjustments by Manifest

### 1. Comtrya.yaml (Main Configuration)
**Tasks:**
- Add platform detection variables
- Create platform-specific variable groups
- Add conditional manifest loading based on platform

**Required Changes:**
```yaml
variables:
  # Platform detection
  platform: "{{ os.family }}"  # linux, darwin
  is_wsl: "{{ env.WSL_DISTRO_NAME != null }}"
  
  # Platform-specific package managers
  package_manager: "{{ platform == 'darwin' ? 'brew' : 'apt' }}"
  
  # Platform-specific paths
  shell_path: "{{ platform == 'darwin' ? '/usr/local/bin/fish' : '/usr/bin/fish' }}"
```

### 2. system-deps.yml (System Dependencies)
**Tasks:**
- Replace APT-specific actions with conditional package installation
- Add Homebrew support for macOS
- Handle PPA repositories conditionally
- Adjust package names for different platforms

**Required Changes:**
- Replace `provider: apt` with conditional providers
- Create platform-specific package lists
- Add Homebrew tap management for macOS
- Handle WSL-specific package considerations

**Platform-Specific Packages:**
- Linux: `software-properties-common`, `autoconf`, `build-essential`, etc.
- macOS: Use Homebrew equivalents
- WSL: May need Windows-specific considerations

### 3. system-deps/docker.yml
**Tasks:**
- Add platform-specific Docker installation methods
- Handle Docker Desktop for macOS/WSL
- Adjust group management for different platforms

**Required Changes:**
- Linux: Keep current Docker CE installation
- macOS: Use Docker Desktop or Colima
- WSL: Use Docker Desktop with WSL2 integration

### 4. system-deps/openssl.yml
**Tasks:**
- Make OpenSSL compilation cross-platform
- Handle different build dependencies
- Adjust compiler flags for different platforms

**Required Changes:**
- Add platform-specific build dependencies
- Handle different OpenSSL versions for macOS
- Adjust make commands for different platforms

### 5. cli/*.yml (CLI Tools)
**Tasks:**
- Make installation scripts cross-platform
- Handle different binary locations
- Adjust PATH modifications

**Required Changes:**
- **mise.yml**: Handle different installation methods
- **atuin.yml**: Adjust for different shell environments
- **starship.yml**: Platform-agnostic (minimal changes)
- **zoxide.yml**: Platform-agnostic (minimal changes)

### 6. user/fish.yml (Fish Shell Configuration)
**Tasks:**
- Handle different Fish installation paths
- Adjust shell change commands for different platforms
- Handle WSL-specific Windows path integration

**Required Changes:**
- Shell path: `/usr/bin/fish` (Linux) vs `/usr/local/bin/fish` (macOS)
- User modification commands may differ
- Add WSL-specific PATH modifications for Windows tools

### 7. user/neovim.yml (Neovim Configuration)
**Tasks:**
- Handle different Neovim installation methods
- Adjust for different clipboard behaviors
- Handle font and rendering differences

**Required Changes:**
- Minimal changes needed as Neovim is cross-platform
- May need platform-specific plugin configurations
- Handle different clipboard providers

### 8. user/git.yml (Git Configuration)
**Tasks:**
- Handle different credential managers
- Adjust for different SSH key locations
- Handle WSL-specific Git configurations

**Required Changes:**
- macOS: Use Keychain for credentials
- Linux: Use libsecret or gnome-keyring
- WSL: Handle Windows credential manager integration

### 9. user/tmux.yml & tmuxp.yml
**Tasks:**
- Handle different clipboard integration
- Adjust for different terminal behaviors

**Required Changes:**
- Minimal changes needed
- May need platform-specific clipboard settings

## Implementation Strategy

### Phase 1: Platform Detection
1. Add platform variables to Comtrya.yaml
2. Create platform-specific variable groups
3. Implement conditional logic in manifests

### Phase 2: Package Management Abstraction
1. Create package manager abstraction layer
2. Define platform-specific package mappings
3. Implement conditional package installation

### Phase 3: Path and Command Adjustments
1. Standardize path variables
2. Handle platform-specific commands
3. Adjust privileged operations

### Phase 4: Testing and Validation
1. Test on each target platform
2. Validate package installations
3. Test configuration applications

## Conditional Logic Patterns

### Package Installation Pattern
```yaml
- action: package.install
  provider: "{{ platform == 'darwin' ? 'brew' : 'apt' }}"
  name: "{{ platform == 'darwin' ? 'package-name-macos' : 'package-name-linux' }}"
```

### Command Execution Pattern
```yaml
- action: command.run
  command: "{{ platform == 'darwin' ? 'brew' : 'apt-get' }}"
  args: ["install", "package-name"]
  when: platform == 'darwin' or platform == 'linux'
```

### File Path Pattern
```yaml
- action: file.copy
  from: config-file
  to: "{{ platform == 'darwin' ? '/usr/local/etc' : '/etc' }}/config-file"
```

## Platform-Specific Considerations

### Linux
- Keep existing APT-based installation
- Handle different distributions (Ubuntu, Debian, Fedora)
- Maintain PPA support where applicable

### macOS
- Use Homebrew as primary package manager
- Handle application installation (.app files)
- Use system Keychain for credentials
- Handle different file system structure

### WSL
- Handle Windows path integration
- Use Windows tools when appropriate
- Handle Docker Desktop integration
- Manage WSL-specific configurations

## Testing Requirements
1. Test each manifest on all target platforms
2. Validate package installations and configurations
3. Test tool functionality after installation
4. Verify cross-platform compatibility of configurations

## Backward Compatibility
- Maintain existing Linux functionality
- Ensure current manifests continue to work
- Provide migration path for existing users
- Document platform-specific features and limitations