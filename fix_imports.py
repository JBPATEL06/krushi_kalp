import os

directory = r'f:\Krushi_kalp1\admin\krushi_kalp\lib'

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                if 'package:krushi_kalp/' in content:
                    new_content = content.replace('package:krushi_kalp/', 'package:krushi_kalp_admin/')
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated: {filepath}")
            except Exception as e:
                print(f"Failed to process {filepath}: {e}")
