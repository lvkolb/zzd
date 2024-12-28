# zzd
## Description 
zzd is a hexdump utility built with Zig. It allows you to inspect the binary content of files in a human-readable format, providing insights into the underlying structure of files.
## Installation 
- Install Zig
Ensure you have Zig installed on your system. You can download it from:
https://ziglang.org/download/
- Clone the Repository:
git clone https://github.com/lvkolb/zzd.git
cd zzd
- Build the Project:
zig build
- Optional: Install the Executable 
Copy the binary to /usr/local/bin (requires admin privileges):
zig build install-to-bin
- Or: Run directly
zig build run -- <your-file>
xample- Or: Run the exe in zig-out/bin (windows example)
zig-out\bin\zzd <your-file> 
## Usage 
After installation, you can use the tool as follows:

zzd <filename>

Example:
sequence.bin as example file (produced /producable with the generate_binary.dat.py)

zzd sequence.bin
OR:
Windows:
zig-out\bin\zzd sequence.bin 
Linux/maxOS
zig-out/bin/zzd sequence.bin