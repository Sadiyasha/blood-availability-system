"""
Seed Routes - Web-accessible database seeding endpoint
"""
from flask import Blueprint, jsonify
from extensions import db
from models.donor import Donor
from models.blood_bank import BloodBank
from models.hospital import Hospital
from models.blood_request import BloodRequest
from models.notification import Notification

seed_bp = Blueprint('seed', __name__)

@seed_bp.route('/seed-database', methods=['GET'])
def seed_database_endpoint():
    """
    Web-accessible endpoint to seed the database with initial data.
    Visit: https://your-backend.onrender.com/api/seed-database
    """
    try:
        # Check if already seeded
        donor_count = Donor.query.count()
        if donor_count > 0:
            return jsonify({
                'status': 'already_seeded',
                'message': 'Database already contains data. Clear it first if you want to re-seed.',
                'current_counts': {
                    'donors': donor_count,
                    'blood_banks': BloodBank.query.count(),
                    'hospitals': Hospital.query.count(),
                    'blood_requests': BloodRequest.query.count(),
                    'notifications': Notification.query.count()
                }
            }), 200

        # Use subprocess to run seed script to avoid import issues
        import subprocess
        import os
        backend_dir = os.path.dirname(os.path.dirname(__file__))
        seed_script = os.path.join(backend_dir, 'seed_database.py')
        
        result = subprocess.run(
            ['python', seed_script],
            cwd=backend_dir,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode == 0:
            return jsonify({
                'status': 'success',
                'message': 'Database seeded successfully!',
                'output': result.stdout,
                'counts': {
                    'donors': Donor.query.count(),
                    'blood_banks': BloodBank.query.count(),
                    'hospitals': Hospital.query.count(),
                    'blood_requests': BloodRequest.query.count(),
                    'notifications': Notification.query.count()
                }
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'Failed to seed database',
                'error': result.stderr
            }), 500
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Failed to seed database: {str(e)}'
        }), 500


@seed_bp.route('/clear-database', methods=['GET'])
def clear_database():
    """
    Clear all data from the database.
    Visit: https://your-backend.onrender.com/api/clear-database
    """
    try:
        # Delete all records
        Notification.query.delete()
        BloodRequest.query.delete()
        BloodBank.query.delete()
        Hospital.query.delete()
        Donor.query.delete()
        
        db.session.commit()
        
        return jsonify({
            'status': 'success',
            'message': 'Database cleared successfully!'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'status': 'error',
            'message': f'Failed to clear database: {str(e)}'
        }), 500
