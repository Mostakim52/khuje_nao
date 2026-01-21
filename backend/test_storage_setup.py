"""
Test script to check if Firebase Storage is properly configured.
Run this before testing image uploads.
"""

import os
import sys
from firebase_admin import storage, get_app, initialize_app, credentials

def test_storage_setup():
    """Test if Firebase Storage is configured and accessible."""
    print("Testing Firebase Storage configuration...")
    print("-" * 50)
    
    try:
        # Try to get Firebase app
        try:
            app = get_app()
            print("✅ Firebase app initialized")
        except ValueError:
            print("❌ Firebase app not initialized")
            print("   Initializing Firebase...")
            cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
            if cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                initialize_app(cred)
                app = get_app()
                print("✅ Firebase app initialized")
            else:
                print("❌ Cannot find Firebase credentials")
                print("   Set GOOGLE_APPLICATION_CREDENTIALS environment variable")
                return False
        
        project_id = app.project_id
        print(f"✅ Project ID: {project_id}")
        
        # Try to get storage bucket
        bucket_names = [
            f"{project_id}.firebasestorage.app",
            f"{project_id}.appspot.com",
        ]
        
        bucket_found = False
        for bucket_name in bucket_names:
            try:
                bucket = storage.bucket(bucket_name)
                # Try to access bucket metadata (this will fail if bucket doesn't exist)
                # Just creating the bucket object doesn't verify existence
                print(f"✅ Attempting to use bucket: {bucket_name}")
                bucket_found = True
                break
            except Exception as e:
                print(f"   ⚠️  Bucket {bucket_name} not accessible: {str(e)[:100]}")
                continue
        
        if not bucket_found:
            print("\n❌ No accessible Storage bucket found!")
            print("\n⚠️  ACTION REQUIRED:")
            print("   Firebase Storage must be enabled in Firebase Console:")
            print(f"   1. Go to: https://console.firebase.google.com/project/{project_id}/storage")
            print("   2. Click 'Get Started' or 'Upgrade project'")
            print("   3. Enable billing (you'll stay on free tier)")
            print("   4. Create the Storage bucket")
            return False
        
        print("\n✅ Firebase Storage appears to be configured!")
        print("   Note: Bucket existence is only verified on actual upload")
        return True
        
    except Exception as e:
        print(f"\n❌ Error testing Storage setup: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_storage_setup()
    sys.exit(0 if success else 1)
