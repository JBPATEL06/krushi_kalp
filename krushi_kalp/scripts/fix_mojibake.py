import os
import glob

def fix_mojibake(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        fixed_content = content.encode('windows-1252').decode('utf-8')
        
        if content != fixed_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(fixed_content)
            print(f"Fixed Mojibake in: {file_path}")
            return True
            
    except Exception as e:
        # If it throws an error (e.g., not decodable natively), try specific known replacements
        replacements = {
            'âœ¨': '✨',
            'ðŸŽ‰': '🎉',
            'ðŸ“¡': '📡',
            'ðŸ§ ': '🧠 ',
            'ðŸ§': '🧠',
            'ðŸ“§': '📧',
            'ðŸ“‚': '📁',
            'ðŸ“‹': '📋',
            'ðŸ“ ': '📌',
            'ðŸ ˜': '🏔️',
            'ðŸ“„': '📄',
            'â˜•': '☕',
            'â‚¹': '₹',
            'âœ“': '✓',
            'âœ—': '✗',
            'â€”': '—',
            'â€“': '–',
            'â€¢': '•',
        }
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original = content
            for corrupted, correct in replacements.items():
                content = content.replace(corrupted, correct)
                
            if content != original:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed manually via Dictionary in: {file_path}")
                return True
        except Exception as e2:
            print(f"Failed entirely on {file_path}: {e2}")

    return False

def main():
    fixed_count = 0
    # Search all dart files
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                if fix_mojibake(file_path):
                    fixed_count += 1
    
    # Also check the markdown files
    for md in ['CLAUDE.md', 'README.md']:
        if os.path.exists(md):
            if fix_mojibake(md):
                fixed_count += 1
                
    print(f"Total files fixed: {fixed_count}")

if __name__ == "__main__":
    main()
