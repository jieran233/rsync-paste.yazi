[中文](README.zh-CN.md) | [English](README.md)

# rsync-paste Plugin

A Yazi file manager plugin that uses rsync for efficient file copy/move operations, especially useful for cross-disk operations.

## Features

- 🚀 Uses rsync for file copy/move operations, more efficient than conventional methods
- 💽 Supports cross-disk operations
- 📊 Shows real-time progress in Yazi's header area
- 📦 Supports batch operations
- 🔔 Displays notification upon completion

## Installation

### Method 1: Using ya package manager

```bash
ya pkg add WayneKent/rsync-paste
```

### Method 2: Manual installation

1. Clone the repository from GitHub:

    ```bash
    git clone https://github.com/WayneKent/rsync-paste.yazi.git
    ```

2. Copy the plugin to Yazi's plugin directory:

    ```bash
    cp -r rsync-paste.yazi ~/.config/yazi/plugins/
    ```

3. Ensure `rsync` is installed (most Linux systems have it by default)

## Usage

1. Select files/directories in Yazi (using spacebar)
2. Use `y` to copy or `x` to cut
3. Navigate to target directory
4. Use `'` to paste

### Required Keybinding Configuration

Add one of these configurations to `~/.config/yazi/keymap.toml`:

```toml
[mgr]
prepend_keymap = [
{ on = ["'"], run = "plugin rsync-paste", desc = "Paste yanked files with rsync" },
]
```

or

```toml
[[mgr.prepend_keymap]]
on = "."
run = "plugin rsync-paste"
desc = "Paste yanked files with rsync"
```

## Preview

![rsync-paste operation preview](rsync-paste.png)

## Technical Details

- Uses rsync's `-a` parameter to preserve file attributes and show progress
- For move operations, copies files first then deletes originals
- Progress information is displayed in Yazi's status bar

## FAQ

**Q: Why use rsync instead of system copy commands?**  
A: rsync is more efficient for cross-disk operations and large file transfers, with better progress feedback.

**Q: How to know when operation is complete?**  
A: System notification will appear upon completion, with final results in status bar.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Thanks to Yazi project for the excellent file manager
- Thanks to rsync development team
