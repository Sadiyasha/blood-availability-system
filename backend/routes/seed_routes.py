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
import os

seed_bp = Blueprint('seed', __name__)

@seed_bp.route('/seed-database', methods=['GET'])
def seed_database():
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

        # Import seed_database function
        import sys
        backend_dir = os.path.dirname(os.path.dirname(__file__))
        sys.path.insert(0, backend_dir)
        
        from seed_database import create_donors, create_hospitals, create_blood_banks, create_blood_requests, create_notifications
        
        # Seed the database
        print("Creating 150 donors...")
        create_donors()
        
        print("Creating 58 hospitals...")
        create_hospitals()
        
        print("Creating 41 blood banks...")
        create_blood_banks()
        
        print("Creating 30 blood requests...")
        create_blood_requests()
        
        print("Creating 20 notifications...")
        create_notifications()
        
        db.session.commit()
        
        return jsonify({
            'status': 'success',
            'message': 'Database seeded successfully!',
            'counts': {
                'donors': Donor.query.count(),
                'blood_banks': BloodBank.query.count(),
                'hospitals': Hospital.query.count(),
                'blood_requests': BloodRequest.query.count(),
                'notifications': Notification.query.count()
            }
        }), 200
        
    except Exception as e:
        db.session.rollback()
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
