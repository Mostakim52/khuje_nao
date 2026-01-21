"""
storage.py

Utility functions for AppWrite Storage operations.
Handles uploading images to AppWrite Storage and generating download URLs.
"""

import os
import requests
from datetime import datetime
from typing import Optional

# AppWrite configuration - loaded from environment variables
APPWRITE_ENDPOINT = os.getenv('APPWRITE_ENDPOINT', '')
APPWRITE_PROJECT_ID = os.getenv('APPWRITE_PROJECT_ID', '')
APPWRITE_API_KEY = os.getenv('APPWRITE_API_KEY', '')
APPWRITE_STORAGE_BUCKET_ID = os.getenv('APPWRITE_STORAGE_BUCKET_ID', '')


def _get_headers() -> dict:
    """
    Get headers for AppWrite API requests.
    
    Returns:
        dict: Headers with API key and project ID.
    """
    if not APPWRITE_API_KEY:
        raise Exception("APPWRITE_API_KEY environment variable is required")
    if not APPWRITE_PROJECT_ID:
        raise Exception("APPWRITE_PROJECT_ID environment variable is required")
    
    return {
        'X-Appwrite-Project': APPWRITE_PROJECT_ID,
        'X-Appwrite-Key': APPWRITE_API_KEY,
        'Content-Type': 'application/json'
    }


def upload_image_to_storage(file_data: bytes, filename: str, folder: str = 'lost-items') -> str:
    """
    Upload an image file to AppWrite Storage.
    
    Args:
        file_data: The file data (bytes).
        filename: The name of the file to save.
        folder: The folder/path in Storage (default: 'lost-items').
    
    Returns:
        str: The file ID or URL of the uploaded image.
    
    Raises:
        Exception: If upload fails.
    """
    try:
        if not APPWRITE_ENDPOINT:
            raise Exception("APPWRITE_ENDPOINT environment variable is required")
        if not APPWRITE_STORAGE_BUCKET_ID:
            raise Exception("APPWRITE_STORAGE_BUCKET_ID environment variable is required")
        
        # Create a unique filename with timestamp to avoid conflicts
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S_%f')
        safe_filename = os.path.basename(filename).replace(' ', '_')
        unique_filename = f"{timestamp}_{safe_filename}"
        
        # Create file path
        file_path = f"{folder}/{unique_filename}" if folder else unique_filename
        
        # AppWrite Storage API endpoint
        url = f"{APPWRITE_ENDPOINT}/storage/buckets/{APPWRITE_STORAGE_BUCKET_ID}/files"
        
        # Prepare multipart form data
        files = {
            'file': (unique_filename, file_data, _get_content_type(filename))
        }
        
        data = {
            'fileId': 'unique()',  # Auto-generate file ID
        }
        
        # Make request (without Content-Type header for multipart)
        headers = {
            'X-Appwrite-Project': APPWRITE_PROJECT_ID,
            'X-Appwrite-Key': APPWRITE_API_KEY,
        }
        
        response = requests.post(url, files=files, data=data, headers=headers)
        
        if response.status_code != 201:
            error_msg = response.text
            try:
                error_json = response.json()
                error_msg = error_json.get('message', error_msg)
            except:
                pass
            raise Exception(f"AppWrite API error ({response.status_code}): {error_msg}")
        
        # Get file ID from response
        file_info = response.json()
        file_id = file_info.get('$id', '')
        
        # Return the file view URL
        file_url = f"{APPWRITE_ENDPOINT}/storage/buckets/{APPWRITE_STORAGE_BUCKET_ID}/files/{file_id}/view"
        return file_url
        
    except requests.exceptions.RequestException as e:
        raise Exception(f"Failed to upload image to AppWrite Storage: {str(e)}")
    except Exception as e:
        raise Exception(f"Failed to upload image to AppWrite Storage: {str(e)}")


def _get_content_type(filename: str) -> str:
    """
    Get content type based on file extension.
    
    Args:
        filename: The filename.
    
    Returns:
        str: Content type.
    """
    extension = os.path.splitext(filename)[1].lower()
    content_types = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
    }
    return content_types.get(extension, 'image/jpeg')


def delete_image_from_storage(file_url: str) -> bool:
    """
    Delete an image from AppWrite Storage using its URL.
    
    Args:
        file_url: The URL of the image to delete.
    
    Returns:
        bool: True if deletion was successful, False otherwise.
    """
    try:
        if not APPWRITE_ENDPOINT or not APPWRITE_STORAGE_BUCKET_ID:
            return False
        
        # Extract file ID from URL
        # URL format: https://endpoint/storage/buckets/{bucketId}/files/{fileId}/view
        url_parts = file_url.split('/files/')
        if len(url_parts) < 2:
            return False
        
        file_id = url_parts[1].split('/')[0]
        
        # Delete file
        url = f"{APPWRITE_ENDPOINT}/storage/buckets/{APPWRITE_STORAGE_BUCKET_ID}/files/{file_id}"
        response = requests.delete(url, headers=_get_headers())
        
        return response.status_code in [200, 204]
    except Exception as e:
        print(f"Error deleting image from AppWrite Storage: {str(e)}")
        return False
