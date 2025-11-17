from extensions import db
from datetime import datetime
from sqlalchemy.dialects.mysql import DECIMAL

class Hospital(db.Model):
    __tablename__ = 'hospitals'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    hospital_type = db.Column(db.Enum('Government', 'Private', 'Trust', 'Military'), default='Government')
    
    # Location
    latitude = db.Column(DECIMAL(10, 8), nullable=False)
    longitude = db.Column(DECIMAL(11, 8), nullable=False)
    
    # Address
    street = db.Column(db.String(200))
    city = db.Column(db.String(100))
    state = db.Column(db.String(100))
    pincode = db.Column(db.String(10))
    country = db.Column(db.String(50), default='India')
    
    # Contact
    phone = db.Column(db.String(20), nullable=False)
    email = db.Column(db.String(100))
    website = db.Column(db.String(200))
    emergency_contact = db.Column(db.String(20), nullable=False)
    
    # Blood bank association
    has_blood_bank = db.Column(db.Boolean, default=False)
    
    # Capacity
    total_beds = db.Column(db.Integer)
    icu_beds = db.Column(db.Integer)
    emergency_beds = db.Column(db.Integer)
    
    # Additional info
    departments = db.Column(db.Text)  # JSON string of departments
    facilities = db.Column(db.Text)  # JSON string of facilities
    rating = db.Column(DECIMAL(2, 1), default=4.0)
    verified = db.Column(db.Boolean, default=True)
    operating_hours = db.Column(db.String(100), default='24/7')
    registration_number = db.Column(db.String(50))
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    blood_banks = db.relationship('BloodBank', back_populates='hospital', lazy='dynamic')
    blood_requests = db.relationship('BloodRequest', back_populates='hospital', lazy='dynamic')
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'hospitalType': self.hospital_type,
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
            'phone': self.phone,
            'email': self.email,
            'website': self.website,
            'emergencyContact': self.emergency_contact,
            'hasBloodBank': self.has_blood_bank,
            'capacity': {
                'totalBeds': self.total_beds,
                'icuBeds': self.icu_beds,
                'emergencyBeds': self.emergency_beds
            },
            'rating': float(self.rating) if self.rating else 4.0,
            'verified': self.verified,
            'operatingHours': self.operating_hours
        }
