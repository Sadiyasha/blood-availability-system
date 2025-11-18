# Flask Application Configuration
import os
from datetime import timedelta

class Config:
    """Base configuration"""
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    
    # Database Configuration
    # Priority: DATABASE_URL (Render/Heroku) > MySQL > SQLite (dev fallback)
    DATABASE_URL = os.environ.get('DATABASE_URL')
    
    if DATABASE_URL:
        # Production: Use DATABASE_URL from Render/Heroku
        # Fix for PostgreSQL (Render uses postgresql://, SQLAlchemy needs postgresql+psycopg2://)
        if DATABASE_URL.startswith('postgres://'):
            DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql+psycopg2://', 1)
        elif DATABASE_URL.startswith('postgresql://'):
            DATABASE_URL = DATABASE_URL.replace('postgresql://', 'postgresql+psycopg2://', 1)
        SQLALCHEMY_DATABASE_URI = DATABASE_URL
    else:
        # Development: Use MySQL or SQLite
        MYSQL_HOST = os.environ.get('MYSQL_HOST') or 'localhost'
        MYSQL_PORT = int(os.environ.get('MYSQL_PORT') or 3306)
        MYSQL_USER = os.environ.get('MYSQL_USER') or 'root'
        MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD') or 'password'
        MYSQL_DATABASE = os.environ.get('MYSQL_DATABASE') or 'blood_availability_system'
        
        USE_SQLITE = os.environ.get('USE_SQLITE', 'True').lower() == 'true'
        
        if USE_SQLITE:
            basedir = os.path.abspath(os.path.dirname(__file__))
            SQLALCHEMY_DATABASE_URI = f'sqlite:///{os.path.join(basedir, "instance", "blood_system.db")}'
        else:
            SQLALCHEMY_DATABASE_URI = f'mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}'
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = False
    
    # Firebase Configuration
    FIREBASE_CONFIG = {
        'apiKey': os.environ.get('FIREBASE_API_KEY'),
        'authDomain': os.environ.get('FIREBASE_AUTH_DOMAIN'),
        'databaseURL': os.environ.get('FIREBASE_DATABASE_URL'),
        'storageBucket': os.environ.get('FIREBASE_STORAGE_BUCKET'),
        'serviceAccount': os.environ.get('FIREBASE_SERVICE_ACCOUNT') or 'firebase-credentials.json'
    }
    
    # Google Maps API
    GOOGLE_MAPS_API_KEY = os.environ.get('GOOGLE_MAPS_API_KEY') or 'YOUR_GOOGLE_MAPS_API_KEY'
    
    # AI/ML Configuration
    MAX_MATCH_DISTANCE_KM = 50
    ML_MODEL_PATH = 'models/'
    # Enable ML matching routes; requirements are installed in this workspace
    USE_ML_MATCHING = True
    # Enable lightweight NLP chatbot (fallbacks avoid heavy deps)
    USE_CHATBOT = True
    # Enable lightweight chatbot (uses regex/NLTK with graceful fallbacks)
    USE_CHATBOT = True
    # Enable lightweight chatbot (uses local NLP fallback if NLTK data is missing)
    USE_CHATBOT = True
    
    # API Configuration
    JSON_SORT_KEYS = False
    RESTFUL_JSON = {'ensure_ascii': False}
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max request size
    
    # CORS Configuration
    CORS_ORIGINS = ['http://localhost:*', 'http://127.0.0.1:*']
    
    # Pagination
    ITEMS_PER_PAGE = 20
    MAX_ITEMS_PER_PAGE = 100

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    SQLALCHEMY_ECHO = True

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False

class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
