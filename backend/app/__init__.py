"""
__init__.py

This module initializes the Flask application, configures the app settings, 
and sets up integrations like Firebase/Firestore and CORS.
"""

import os
import logging
from flask import Flask
from flask_cors import CORS
from firebase_admin import credentials, initialize_app, get_app
from config import Config
import json

# Get the base directory of the application
basedir = os.path.abspath(os.path.dirname(__file__))


def create_app():
    """
    Creates and configures the Flask application.

    The application is configured with:
        - Firebase Admin SDK for Firestore integration.
        - Flask-CORS for Cross-Origin Resource Sharing.
        - Logging for debugging and monitoring.

    Returns:
        Flask: The initialized Flask application instance.
    """
    firebase_cred_json = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    if firebase_cred_json:
        cred = credentials.Certificate(json.loads(firebase_cred_json))
        initialize_app(cred)

    # Create the Flask app instance
    app = Flask(__name__)

    # Load configuration from the Config object
    app.config.from_object(Config)

    # Define allowed file extensions for uploads (used for validation)
    app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg'}

    # Initialize Firebase Admin SDK
    try:
        get_app()  # Check if Firebase is already initialized
    except ValueError:
        # Firebase not initialized, initialize it now
        cred_path = Config.GOOGLE_APPLICATION_CREDENTIALS
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            initialize_app(cred)
        else:
            # Try to use default credentials (e.g., from environment or GCP)
            try:
                initialize_app()
            except Exception as e:
                logger = logging.getLogger(__name__)
                logger.warning(f"Firebase initialization failed: {e}")
                logger.warning("Firebase will be initialized later when needed (e.g., in auth module)")

    # Enable Cross-Origin Resource Sharing (CORS)
    CORS(app)

    # Configure logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logger.info("Server is starting...")

    # Import and register the main blueprint for views
    from .views import main_bp
    app.register_blueprint(main_bp)

    # Register auth blueprint (Firebase/OTP/Profiles)
    try:
        from .auth import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/')
    except Exception as e:
        logger.warning(f"Auth blueprint not registered: {e}")

    return app
