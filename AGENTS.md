# AGENTS.md

Welcome to the `nix-config` repository! This document contains instructions, guidelines, and context designed to help AI coding assistants (agents) operate efficiently and safely in this codebase.

## Repository Overview

This is a NixOS configuration repository organized using a **dendritic module pattern**. It leverages `flake-parts` and `import-tree` to automatically structure and compose modules.

**CRITICAL RULE: DO NOT EDIT `flake.nix` DIRECTLY.**
The `flake.nix` file is automatically generated. Any changes must be done by modifying the Nix files inside the `modules/` directory. If you need to regenerate the flake, ask the user to run the following command (as it requires `sudo` privileges which agents lack):
```bash
nix run .#write-flake
```

## 1. Build, Lint, and Test Commands

### Building Configurations
Since this repository defines NixOS and Home Manager systems, you will primarily verify changes by evaluating or building the configurations.

- **Check Flake Validity:** Validate the structure and syntax of the entire flake:
  ```bash
  nix flake check
  ```
- **Show Flake Outputs:** See what systems and packages are available:
  ```bash
  nix flake show
  ```
- **Build the `frameworkDesktop` Host:**
  To build the system configuration for the Framework laptop without activating it:
  ```bash
  nixos-rebuild build --flake .#frameworkDesktop
  ```
  *(Note: To activate the configuration, ask the user to run `sudo nixos-rebuild switch --flake .#frameworkDesktop`, as agents lack the required `sudo` privileges.)*
- **Build a Home Manager Configuration (if present):**
  ```bash
  home-manager build --flake .#mosqueteiro@frameworkDesktop
  ```

### Linting and Formatting
Consistent code style is enforced via Nix formatters.
- **Format all files:**
  ```bash
  nix fmt
  ```
  *(Note: if `nix fmt` is not defined in the flake, use `nixpkgs-fmt .` or `alejandra .` as a fallback.)*

### Running a Single "Test"
In a declarative Nix configuration, testing typically means evaluating a specific module or expression to ensure it builds without syntax or evaluation errors.
- **Evaluate a specific configuration:**
  To test if a host evaluates correctly without building the entire system closure:
  ```bash
  nix eval .#nixosConfigurations.frameworkDesktop.config.system.build.toplevel.drvPath
  ```
- **Debugging Nix errors:**
  When a Nix command fails, use `--show-trace` to get a detailed stack trace:
  ```bash
  nix flake check --show-trace
  ```

## 2. Code Style Guidelines

### File Structure and Imports
- **Dendritic Pattern:** Do not manually add `import ./some-file.nix` to `flake.nix`. Instead, place your new Nix modules inside the `modules/` directory. The `import-tree` tool automatically discovers and imports them.
- **Directory Layout:**
  - `modules/hosts/`: Host-specific configurations (e.g., `framework-desktop`).
  - `modules/users/`: User-specific configurations (e.g., `mosqueteiro`).
  - `modules/system/`: System-wide NixOS configurations and base modules.
  - `modules/nix/`: Core Nix and flake-parts configuration (e.g., `lib.nix`).
- **Use `flake-parts`:** Rely on `flake-parts` module system (`perSystem`, `flake`, etc.) to declare outputs.

### Naming Conventions
- **Files and Directories:** Use `kebab-case` for file names and directory names (e.g., `framework-desktop`, `flake-parts.nix`).
- **Nix Variables and Attributes:** Use `camelCase` for internal variable names, functions, and NixOS option declarations (e.g., `frameworkDesktop`, `isNormalUser`).
- **Hostnames:** Typically follow `kebab-case` or match their folder name directly.

### Formatting and Syntax
- Use 2 spaces for indentation.
- Always use spaces around operators (e.g., `foo = bar;` not `foo=bar;`).
- Prefer `with pkgs; [ ... ]` for long package lists to improve readability, but avoid `with pkgs;` at the top level of a module to prevent namespace pollution.
- Use multi-line strings (`''`) for complex scripts or configuration file contents.

### Types and Options
- When creating custom modules, always use the `lib.mkOption` system to declare types, default values, and descriptions.
- Example:
  ```nix
  options.myModule.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable my custom module";
  };
  ```

### Error Handling
- Use `lib.mkIf` to conditionally apply configurations based on other options.
- Use `lib.asserts` or the `assertions = [ ... ]` NixOS option if a specific combination of configurations is invalid or unsafe.
  ```nix
  config = lib.mkIf config.myModule.enable {
    assertions = [
      {
        assertion = config.services.xserver.enable;
        message = "myModule requires X11 to be enabled.";
      }
    ];
  };
  ```

## 3. General Best Practices

- **Modularity:** Keep modules small and focused on a single responsibility (e.g., separating hardware configuration, desktop environment, and CLI tools into different files).
- **Immutability and Purity:** Never rely on the state of the local file system outside of the flake. All inputs must be declared in `inputs` in the respective `flake-parts` files.
- **Comments:** Document *why* a complex configuration is necessary, especially if working around a known bug or hardware quirk (e.g., DisplayLink configurations).

---
*End of AGENTS.md*
