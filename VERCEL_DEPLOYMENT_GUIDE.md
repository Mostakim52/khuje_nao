# Vercel Deployment Guide

## Prerequisites

1. Vercel account (sign up at https://vercel.com)
2. GitHub repository with your code
3. All environment variables ready

## Step 1: Connect Repository to Vercel

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click **"Add New..."** → **"Project"**
3. Import your GitHub repository (`khuje_nao`)
4. Configure the project:
   - **Framework Preset:** Other
   - **Root Directory:** `backend`
   - **Build Command:** (leave empty)
   - **Output Directory:** (leave empty)
   - **Install Command:** (leave empty)

## Step 2: Set Environment Variables

In Vercel project settings, add these environment variables:

### Required Environment Variables

```
SECRET_KEY=your-secret-key-here
GOOGLE_APPLICATION_CREDENTIALS=backend/firebase_key/your-firebase-key.json
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your-project-id
APPWRITE_API_KEY=your-api-key
APPWRITE_STORAGE_BUCKET_ID=your-bucket-id
```

### Important Notes for Firebase Credentials on Vercel

**Option 1: Store Firebase JSON as Environment Variable (Recommended)**
1. Open your Firebase service account JSON file
2. Copy the entire JSON content
3. In Vercel, create environment variable:
   - **Name:** `FIREBASE_SERVICE_ACCOUNT`
   - **Value:** Paste the entire JSON (minified)
4. Update `backend/app/__init__.py` to read from this env var:

```python
import json
import os

# In create_app() function:
firebase_cred_json = os.getenv("FIREBASE_SERVICE_ACCOUNT")
if firebase_cred_json:
    cred = credentials.Certificate(json.loads(firebase_cred_json))
    initialize_app(cred)
```

**Option 2: Use File Path (Requires Upload)**
- Upload the Firebase key file to your repo (NOT RECOMMENDED - security risk)
- Set `GOOGLE_APPLICATION_CREDENTIALS` to the file path

## Step 3: Deploy

1. Click **"Deploy"**
2. Wait for deployment to complete
3. Copy your deployment URL (e.g., `https://your-app.vercel.app`)

## Step 4: Update Flutter App

Update `lib/api_config.dart`:

```dart
static const String baseUrl = 'https://your-app.vercel.app';
```

## Step 5: Test Deployment

1. Test the root endpoint: `https://your-app.vercel.app/`
2. Test authentication: `https://your-app.vercel.app/firebase-google-login`
3. Verify all endpoints work correctly

## Troubleshooting

### Issue: Environment variables not working
- Make sure variables are set in Vercel dashboard
- Redeploy after adding/updating variables
- Check variable names match exactly (case-sensitive)

### Issue: Firebase initialization fails
- Verify Firebase JSON is valid
- Check if using Option 1, ensure JSON is properly minified
- Check Vercel logs for detailed error messages

### Issue: CORS errors
- Verify Flask-CORS is properly configured
- Check if your Flutter app URL is in allowed origins

### Issue: Module not found errors
- Ensure `requirements.txt` is up to date
- Check Vercel build logs for missing dependencies

## Vercel Configuration File

The `backend/vercel.json` file is already configured:

```json
{
  "builds": [
    { "src": "run.py", "use": "@vercel/python" }
  ],
  "routes": [
    { "src": "/(.*)", "dest": "run.py" }
  ]
}
```

This configuration tells Vercel to:
- Use Python runtime
- Route all requests to `run.py` (Flask app entry point)

## Production Checklist

- [ ] All environment variables set in Vercel
- [ ] Firebase credentials configured
- [ ] AppWrite credentials configured
- [ ] API config updated in Flutter app
- [ ] All endpoints tested
- [ ] CORS working correctly
- [ ] Error handling verified

## Updating After Deployment

After pushing changes to GitHub:
1. Vercel automatically detects changes
2. Triggers new deployment
3. Your app updates automatically

Or manually redeploy:
1. Go to Vercel dashboard
2. Click on your project
3. Go to "Deployments" tab
4. Click "Redeploy"
