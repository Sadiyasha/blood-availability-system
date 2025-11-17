from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from config import config
import os
from extensions import db, migrate

# Initialize extensions (moved to extensions.py)

def create_app(config_name='development'):
    """Application factory pattern"""
    app = Flask(__name__)
    
    # Load configuration
    app.config.from_object(config[config_name])
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    
    # Register blueprints
    from routes.donor_routes import donor_bp
    from routes.hospital_routes import hospital_bp
    from routes.blood_bank_routes import blood_bank_bp
    from routes.blood_request_routes import blood_request_bp
    # smart_match is optional because it depends on heavy ML libraries
    # Allow environment variable to override config to ease local runs
    smart_match_bp = None
    use_ml_env = os.getenv('USE_ML_MATCHING')
    use_ml_matching = (
        (str(use_ml_env).lower() == 'true') if use_ml_env is not None else bool(app.config.get('USE_ML_MATCHING'))
    )
    if use_ml_matching:
        try:
            from routes.smart_match_routes import smart_match_bp
        except Exception as e:
            # Log and continue without ML routes
            print(f"⚠️  Could not load smart_match_routes: {e}")
            smart_match_bp = None
    from routes.notification_routes import notification_bp
    
    # Chatbot disabled to avoid NLTK/scipy heavy dependencies during quick dev
    chatbot_bp = None
    use_chatbot_env = os.getenv('USE_CHATBOT')
    use_chatbot = (
        (str(use_chatbot_env).lower() == 'true') if use_chatbot_env is not None else bool(app.config.get('USE_CHATBOT'))
    )
    if use_chatbot:
        try:
            from routes.chatbot_routes import chatbot_bp
        except Exception as e:
            print(f"⚠️  Could not load chatbot_routes: {e}")
            chatbot_bp = None
    
    from routes.map_routes import map_bp
    
    app.register_blueprint(donor_bp, url_prefix='/api/donors')
    app.register_blueprint(hospital_bp, url_prefix='/api/hospitals')
    app.register_blueprint(blood_bank_bp, url_prefix='/api/blood-banks')
    app.register_blueprint(blood_request_bp, url_prefix='/api/blood-requests')
    if smart_match_bp:
        app.register_blueprint(smart_match_bp, url_prefix='/api/smart-match')
    app.register_blueprint(notification_bp, url_prefix='/api/notifications')
    if chatbot_bp:
        app.register_blueprint(chatbot_bp, url_prefix='/api/chatbot')
    app.register_blueprint(map_bp, url_prefix='/api/map')
    
    # Root and health endpoints
    @app.route('/')
    def index():
        return {
            'message': '🩸 Blood Availability System API',
            'version': '1.0.0',
            'status': 'running',
            'features': [
                'AI/ML Donor Matching',
                'Google Maps Integration',
                'Firebase Real-time',
                'Intelligent Chatbot',
                'Predictive Analytics'
            ],
            'endpoints': {
                'health': '/api/health',
                'donors': '/api/donors',
                'hospitals': '/api/hospitals',
                'bloodBanks': '/api/blood-banks',
                'bloodRequests': '/api/blood-requests',
                'smartMatch': '/api/smart-match',
                'notifications': '/api/notifications',
                'chatbot': '/api/chatbot',
                'map': '/api/map'
            }
        }
    
    @app.route('/api/health')
    def health():
        try:
            # Check database connection (SQLAlchemy 2.0 compatible)
            from sqlalchemy import text
            db.session.execute(text('SELECT 1'))
            db_status = 'Connected'
        except Exception as _:
            db_status = 'Disconnected'
        
        return {
            'success': True,
            'message': 'Blood Availability System API is running',
            'database': db_status,
            'ai_enabled': app.config['USE_ML_MATCHING'],
            'maps_configured': bool(app.config['GOOGLE_MAPS_API_KEY'] != 'YOUR_GOOGLE_MAPS_API_KEY')
        }
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return {'success': False, 'message': 'Endpoint not found'}, 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return {'success': False, 'message': 'Internal server error'}, 500
    
    # Initialize optional services that need app context
    try:
        from services.google_maps_service import init_maps_service
        init_maps_service(app)
    except Exception:
        # If google maps service fails to initialize, don't break the app
        pass

    return app

if __name__ == '__main__':
    env = os.getenv('FLASK_ENV', 'development')
    app = create_app(env)
    port = int(os.getenv('PORT', 5000))
    # Disable debug mode and reloader to avoid import issues with heavy dependencies
    app.run(host='0.0.0.0', port=port, debug=False, use_reloader=False)
