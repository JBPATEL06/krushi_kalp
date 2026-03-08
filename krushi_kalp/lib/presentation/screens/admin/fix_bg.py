import os, re

target_dir = "f:/Krushi_kalp1/krushi_kalp/lib/presentation/screens/admin/"

count = 0
for root, dirs, files in os.walk(target_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace backgroundColor: colorScheme.surface,
            new_content = re.sub(
                r'backgroundColor:\s*colorScheme\.surface\s*,',
                'backgroundColor: Theme.of(context).scaffoldBackgroundColor,',
                content
            )
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Updated {file}')
                count += 1

print(f'Total files updated: {count}')
