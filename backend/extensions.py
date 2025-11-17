from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

# Singletons for extensions to avoid double-import issues when running the app
db = SQLAlchemy()
migrate = Migrate()
