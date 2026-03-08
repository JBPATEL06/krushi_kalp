import os
import re

def audit_android_compat():
    print("--- Android Compatibility Audit Report ---")
    issues_found = 0

    # 1. Check minSdkVersion in android/app/build.gradle
    gradle_path = "android/app/build.gradle"
    if os.path.exists(gradle_path):
        with open(gradle_path, 'r') as f:
            content = f.read()
            min_sdk_match = re.search(r'minSdkVersion\s+(\d+)', content)
            if min_sdk_match:
                min_sdk = int(min_sdk_match.group(1))
                if min_sdk < 26:
                    print(f"[ISSUE] minSdkVersion is {min_sdk}. Target is API 26 (Android 8.0).")
                    issues_found += 1
            
            # Check for deprecated Gradle features or old compileSDK if needed
            compile_sdk_match = re.search(r'compileSdkVersion\s+(\d+)', content)
            if compile_sdk_match:
                compile_sdk = int(compile_sdk_match.group(1))
                if compile_sdk < 33:
                    print(f"[WARNING] compileSdkVersion is {compile_sdk}. Recommend API 33 or 34.")

    # 2. Check pubspec.yaml for known old/incompatible plugins
    pubspec_path = "pubspec.yaml"
    if os.path.exists(pubspec_path):
        with open(pubspec_path, 'r') as f:
            content = f.read()
            # Example: check for very old flutter_local_notifications which might have issues with API 26+ background limits
            # Or other plugins that dropped support for older APIs
            # This is a bit speculative without a full DB, but we can look for "ancient" versions
            pass

    # 3. Check for obvious Android-only APIs in Dart that might need guards or specific versions
    # (e.g., legacy permission handling)
    
    # 4. Check for multidex if needed (usually handled by Flutter now)

    print("------------------------------------------")
    print(f"Total Android compatibility issues found: {issues_found}")

if __name__ == "__main__":
    audit_android_compat()
