from extensions import db
from datetime import datetime
from sqlalchemy.dialects.mysql import DECIMAL

class Donor(db.Model):
    __tablename__ = 'donors'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    blood_type = db.Column(db.Enum('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'), nullable=False)
    phone = db.Column(db.String(20), nullable=False, unique=True)
    email = db.Column(db.String(100))
    age = db.Column(db.Integer, nullable=False)
    gender = db.Column(db.Enum('Male', 'Female', 'Other'))
    
    # Location (latitude, longitude)
    latitude = db.Column(DECIMAL(10, 8), nullable=False)
    longitude = db.Column(DECIMAL(11, 8), nullable=False)
    
    # Address
    street = db.Column(db.String(200))
    city = db.Column(db.String(100))
    state = db.Column(db.String(100))
    pincode = db.Column(db.String(10))
    country = db.Column(db.String(50), default='India')
    
    # Donation details
    last_donation_date = db.Column(db.Date)
    available_for_donation = db.Column(db.Boolean, default=True)
    total_donations = db.Column(db.Integer, default=0)
    
    # Medical history (stored as JSON string)
    has_chronic_diseases = db.Column(db.Boolean, default=False)
    medical_notes = db.Column(db.Text)
    
    # Emergency contact
    emergency_contact_name = db.Column(db.String(100))
    emergency_contact_phone = db.Column(db.String(20))
    emergency_contact_relation = db.Column(db.String(50))
    
    # Verification and rating
    verified = db.Column(db.Boolean, default=True)
    rating = db.Column(DECIMAL(2, 1), default=5.0)
    response_time_minutes = db.Column(db.Integer, default=30)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    blood_requests = db.relationship('BloodRequestMatch', back_populates='donor', lazy='dynamic')
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'bloodType': self.blood_type,
            'phone': self.phone,
            'email': self.email,
            'age': self.age,
            'gender': self.gender,
            'location': {
                'latitude': float(self.latitude) if self.latitude else None,
                'longitude': float(self.longitude) if self.longitude else None
            },
            'address': {
                'street': self.street,
                'city': self.city,
                'state': self.state,
                'pincode': self.pincode,
                'country': self.country
            },
            'lastDonationDate': self.last_donation_date.isoformat() if self.last_donation_date else None,
            'availableForDonation': self.available_for_donation,
            'totalDonations': self.total_donations,
            'verified': self.verified,
            'rating': float(self.rating) if self.rating else 5.0,
            'responseTime': self.response_time_minutes,
            'createdAt': self.created_at.isoformat() if self.created_at else None
        }
