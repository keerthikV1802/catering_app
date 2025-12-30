import os

# Define replacements
# We target the literal characters that are appearing in the corrupted files
replacements = {
    'â‚¹': 'Rs. ',
    '‚¹': 'Rs. ',
    'Ã—': 'x',
    '₹': 'Rs. '
}

def cleanup_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content
        for old, new in replacements.items():
            new_content = new_content.replace(old, new)
        
        if content != new_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed: {filepath}")
    except Exception as e:
        print(f"Error processing {filepath}: {e}")

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                cleanup_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
