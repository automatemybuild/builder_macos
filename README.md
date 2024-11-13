By using these scripts, you acknowledge and accept the risk of potential data loss or system alteration. Proceed at your own risk.

### Prerequisites

-  macOS (The scripts are tailored for macOS)

### Installation

1. Clone the repository to your local machine:
   ```sh
   git clone https://github.com/automatemybuild/builder_macos.git ~/git/builder
   ```
2. Navigate to the `dotfiles` directory:
   ```sh
   cd ~/git/builder_macos/start_here
   ```
3. Run the installation script:
   ```sh
   ./install.sh
   ```
4. Run the builder script:
   ```sh
   ./builder.sh macos.playbook
   ```

This script will:

-  Create symlinks for dotfiles (`.bashrc`, `.zshrc`, etc.)
-  Run macOS-specific configurations
-  Install Homebrew packages and casks

## License

This project is licensed under the MIT License - see the [LICENSE-MIT.txt](LICENSE-MIT.txt) file for details.
