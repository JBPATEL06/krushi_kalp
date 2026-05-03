import struct
import sys
import os
import glob

def check_alignment(file_path):
    with open(file_path, "rb") as f:
        e_ident = f.read(16)
        if e_ident[:4] != b"\x7fELF":
            return False, "Not an ELF file"
        
        is_64bit = e_ident[4] == 2
        endian = e_ident[5]
        
        if not is_64bit:
            return False, "Not 64-bit (we only care about 64-bit alignment usually, but okay)"
            
        f.seek(32)
        e_phoff = struct.unpack("<Q" if endian == 1 else ">Q", f.read(8))[0]
        
        f.seek(54)
        e_phentsize = struct.unpack("<H" if endian == 1 else ">H", f.read(2))[0]
        e_phnum = struct.unpack("<H" if endian == 1 else ">H", f.read(2))[0]
        
        f.seek(e_phoff)
        for i in range(e_phnum):
            ph_data = f.read(e_phentsize)
            if is_64bit:
                # Elf64_Phdr is 56 bytes
                p_type, p_flags, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align = struct.unpack("<IIQQQQQQ" if endian == 1 else ">IIQQQQQQ", ph_data[:56])
            else:
                p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align = struct.unpack("<IIIIIIII" if endian == 1 else ">IIIIIIII", ph_data[:32])
                
            if p_type == 1: # PT_LOAD
                if p_align < 16384:
                    return False, f"LOAD segment {i} alignment is {p_align} (needs 16384)"
                    
    return True, "Aligned to 16KB or more"

paths = glob.glob("build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/**/*.so", recursive=True)
for path in paths:
    aligned, msg = check_alignment(path)
    if not aligned:
        print(f"FAILED: {path} - {msg}")
    else:
        print(f"OK: {path} - {msg}")

