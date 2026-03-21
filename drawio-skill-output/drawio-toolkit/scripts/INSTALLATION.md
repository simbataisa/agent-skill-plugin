# Draw.io CLI Scripts - Installation & Setup

## Installation

### Prerequisites
- Python 3.7 or higher
- pip (Python package manager)

### Step 1: Install Dependencies

```bash
pip install lxml
```

### Step 2: Verify Installation

```bash
# Test that lxml is installed
python3 -c "from lxml import etree; print('lxml OK')"
```

### Step 3: Verify Scripts

Navigate to the scripts directory and check help:

```bash
cd drawio/scripts

python3 validate.py --help
python3 convert.py --help
python3 auto_layout.py --help
python3 merge.py --help
python3 info.py --help
python3 create_from_csv.py --help
```

### Step 4: Run Tests (Optional)

```bash
python3 test_scripts.py
```

Expected output: "✓ All tests passed!"

## Usage

Each script can be run from anywhere on your system:

```bash
# If scripts are in /path/to/drawio/scripts
python3 /path/to/drawio/scripts/validate.py diagram.drawio

# Or add to PATH for easier access
export PATH="/path/to/drawio/scripts:$PATH"
validate.py diagram.drawio  # Now works from anywhere
```

## Linux/macOS Setup

### Option 1: Add to PATH

```bash
# Add this to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/drawio/scripts"

# Reload shell
source ~/.bashrc
```

### Option 2: Create Symlinks

```bash
ln -s /path/to/drawio/scripts/validate.py /usr/local/bin/validate-drawio
ln -s /path/to/drawio/scripts/convert.py /usr/local/bin/convert-drawio
ln -s /path/to/drawio/scripts/auto_layout.py /usr/local/bin/layout-drawio
ln -s /path/to/drawio/scripts/merge.py /usr/local/bin/merge-drawio
ln -s /path/to/drawio/scripts/info.py /usr/local/bin/info-drawio
ln -s /path/to/drawio/scripts/create_from_csv.py /usr/local/bin/create-drawio
```

### Option 3: Create Bash Aliases

```bash
# Add to ~/.bashrc or ~/.zshrc
alias drawio-validate="python3 /path/to/drawio/scripts/validate.py"
alias drawio-convert="python3 /path/to/drawio/scripts/convert.py"
alias drawio-layout="python3 /path/to/drawio/scripts/auto_layout.py"
alias drawio-merge="python3 /path/to/drawio/scripts/merge.py"
alias drawio-info="python3 /path/to/drawio/scripts/info.py"
alias drawio-create="python3 /path/to/drawio/scripts/create_from_csv.py"

# Reload shell
source ~/.bashrc
```

## Windows Setup

### Option 1: Add to PATH (GUI)

1. Open Environment Variables:
   - Press `Win + R`, type `sysdm.cpl`, press Enter
   - Go to "Advanced" tab → "Environment Variables"
   - Click "New" under "User variables"
   - Variable name: `PATH`
   - Variable value: `C:\path\to\drawio\scripts`
   - Click OK

2. Restart terminal/Command Prompt

### Option 2: Create Batch Wrappers

Create `validate-drawio.bat`:
```batch
@echo off
python C:\path\to\drawio\scripts\validate.py %*
```

Save similar files for other scripts in a directory that's in your PATH.

### Option 3: Use Python Launcher

```cmd
py C:\path\to\drawio\scripts\validate.py diagram.drawio
```

## Docker Setup (Optional)

Create `Dockerfile`:
```dockerfile
FROM python:3.9-slim
RUN pip install lxml
COPY drawio/scripts /app/scripts
WORKDIR /app/scripts
ENTRYPOINT ["python3"]
```

Build and use:
```bash
docker build -t drawio-cli .
docker run -v $(pwd):/data drawio-cli validate.py /data/diagram.drawio
```

## Verify Installation

Test the complete setup with the test suite:

```bash
cd drawio/scripts
python3 test_scripts.py
```

Expected output: All 17 tests pass

## Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'lxml'"

**Solution:**
```bash
pip install --upgrade lxml
```

### Issue: "Permission denied" on Linux/macOS

**Solution:**
```bash
chmod +x /path/to/drawio/scripts/*.py
```

### Issue: "python3: command not found" on Windows

**Solution:**
- Ensure Python is installed from https://www.python.org
- Check "Add Python to PATH" during installation
- Or use the Python launcher: `py script.py`

### Issue: Scripts not found in PATH

**Solution:**
```bash
# Check if directory is in PATH
echo $PATH  # Linux/macOS
echo %PATH%  # Windows

# Add the scripts directory to PATH (see options above)
```

## Upgrading

To update all scripts:

1. Get the latest version from the repository
2. Copy the updated `.py` files to your scripts directory
3. Re-run the test suite to verify:
   ```bash
   python3 test_scripts.py
   ```

## Getting Help

Each script includes comprehensive help:

```bash
python3 validate.py --help
python3 convert.py --help
python3 auto_layout.py --help
python3 merge.py --help
python3 info.py --help
python3 create_from_csv.py --help
```

For more information, see:
- `SCRIPTS_README.md` - Complete documentation
- `QUICK_REFERENCE.md` - Common tasks and one-liners
