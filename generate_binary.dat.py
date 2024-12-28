def create_test_binary():
    # Open file in binary write mode
    with open("binary.dat", "wb") as f:
        # ASCII text section
        f.write(b"Hello, World!\n")
        
        # Null bytes
        f.write(b"\x00" * 8)
        
        # Binary counting pattern
        f.write(bytes(range(0, 16)))
        
        # Mixed ASCII and control characters
        f.write(b"Test\x01\x02\x03 123\xff\xfe\n")
        
        # Repeating pattern
        f.write(b"\xaa\xbb" * 4)
        
        # UTF-8 characters
        f.write("こんにちは".encode('utf-8'))
        
        # All bits set
        f.write(b"\xff" * 8)
        
        # Alternating bits
        f.write(b"\x55\xaa" * 4)
        
        # Common file signatures
        f.write(b"PNG\r\n\x1a\n")  # PNG-like header
        f.write(b"GIF89a")         # GIF-like header

if __name__ == "__main__":
    create_test_binary()