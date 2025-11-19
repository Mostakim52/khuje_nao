from flask import Blueprint, request, jsonify
from firebase_admin import auth as fb_auth, credentials, initialize_app, get_app
from . import mongo
import os
import base64
import json
import jwt  # PyJWT


auth_bp = Blueprint('auth', __name__)


def _ensure_firebase_admin():
    # Initialize Firebase Admin once
    try:
        get_app()
        return
    except Exception:
        pass
    cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    if cred_path and os.path.exists(cred_path):
        initialize_app(credentials.Certificate(cred_path))
    else:
        # Fallback to default application credentials (e.g., env or metadata)
        try:
            initialize_app()
        except Exception:
            pass


def _verify_id_token_from_auth_header():
    _ensure_firebase_admin()
    auth_header = request.headers.get('Authorization', '')
    token = None
    if auth_header.startswith('Bearer '):
        token = auth_header.split(' ', 1)[1]
    else:
        # Fallback: allow idToken in JSON body for convenience
        body = request.get_json(silent=True) or {}
        token = body.get('idToken')
    if not token:
        return None
    try:
        return fb_auth.verify_id_token(token)
    except Exception:
        # Dev fallback: allow unsigned decode if SKIP_FIREBASE_VERIFY=true
        if os.getenv('SKIP_FIREBASE_VERIFY', '').lower() in ('1', 'true', 'yes'):
            try:
                # WARNING: Insecure decode for development only
                return jwt.decode(token, options={"verify_signature": False})
            except Exception:
                return None
        return None


@auth_bp.route('/firebase-google-login', methods=['POST'])
def firebase_google_login():
    _ensure_firebase_admin()
    body = request.get_json(silent=True) or {}
    id_token = body.get('idToken')
    if not id_token:
        return jsonify({'error': 'idToken required'}), 400
    try:
        decoded = fb_auth.verify_id_token(id_token)
        uid = decoded.get('uid')
        email = decoded.get('email')
        if not email:
            return jsonify({'error': 'Email not present in token'}), 400

        # Upsert user profile in Mongo by Firebase uid or email
        profile = mongo.db.users.find_one({'firebase_uid': uid}) or mongo.db.users.find_one({'email': email})
        if not profile:
            mongo.db.users.insert_one({
                'firebase_uid': uid,
                'email': email,
                'profile_complete': False,
            })
        else:
            # ensure uid is saved
            mongo.db.users.update_one({'_id': profile['_id']}, {'$set': {'firebase_uid': uid}})

        return jsonify({'message': 'Token verified', 'uid': uid, 'email': email}), 200
    except Exception as e:
        return jsonify({'error': f'Invalid token: {e}'}), 401


@auth_bp.route('/profile', methods=['GET', 'POST'])
def profile():
    decoded = _verify_id_token_from_auth_header()
    if not decoded:
        return jsonify({'error': 'Unauthorized'}), 401
    uid = decoded.get('uid')
    email = decoded.get('email')
    if request.method == 'GET':
        profile = mongo.db.users.find_one({'firebase_uid': uid}) or mongo.db.users.find_one({'email': email})
        if not profile:
            return jsonify({'email': email, 'profile_complete': False}), 200
        profile['_id'] = str(profile['_id'])
        return jsonify({k: v for k, v in profile.items() if k != 'password'}), 200

    # POST
    data = request.get_json(silent=True) or {}
    name = data.get('name')
    nsu_id = data.get('nsu_id')
    phone = data.get('phone')
    if not name or not nsu_id or not phone:
        return jsonify({'error': 'name, nsu_id and phone are required'}), 400

    update = {
        'name': name,
        'nsu_id': str(nsu_id),
        'phone_number': phone,
        'profile_complete': True,
        'firebase_uid': uid,
        'email': email,
    }
    mongo.db.users.update_one(
        {'$or': [{'firebase_uid': uid}, {'email': email}]},
        {'$set': update},
        upsert=True,
    )
    return jsonify({'message': 'Profile saved'}), 200


