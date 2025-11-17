from extensions import db
from datetime import datetime
from sqlalchemy.dialects.mysql import DECIMAL

class BloodBank(db.Model):
    __tablename__ = 'blood_banks'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    
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
    
    # Hospital association
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'))
    
    # Blood inventory
    inventory_a_positive = db.Column(db.Integer, default=0)
    inventory_a_negative = db.Column(db.Integer, default=0)
    inventory_b_positive = db.Column(db.Integer, default=0)
    inventory_b_negative = db.Column(db.Integer, default=0)
    inventory_ab_positive = db.Column(db.Integer, default=0)
    inventory_ab_negative = db.Column(db.Integer, default=0)
    inventory_o_positive = db.Column(db.Integer, default=0)
    inventory_o_negative = db.Column(db.Integer, default=0)
    
    # Operating info
    operating_hours_weekdays = db.Column(db.String(50), default='8:00 AM - 8:00 PM')
    operating_hours_weekends = db.Column(db.String(50), default='9:00 AM - 5:00 PM')
    license_number = db.Column(db.String(50))
    verified = db.Column(db.Boolean, default=True)
    last_inventory_update = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    hospital = db.relationship('Hospital', back_populates='blood_banks')
    
    def get_inventory(self):
        return {
            'A+': self.inventory_a_positive,
            'A-': self.inventory_a_negative,
            'B+': self.inventory_b_positive,
            'B-': self.inventory_b_negative,
            'AB+': self.inventory_ab_positive,
            'AB-': self.inventory_ab_negative,
            'O+': self.inventory_o_positive,
            'O-': self.inventory_o_negative
        }
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'location': {
                'latitude': float(self.latitude) if self.latitude else None,
                'longitude': float(self.longitude) if self.longitude else None
            },
            'latitude': float(self.latitude) if self.latitude else None,
            'longitude': float(self.longitude) if self.longitude else None,
            'address': {
                'street': self.street,
                'city': self.city,
                'state': self.state,
                'pincode': self.pincode,
                'country': self.country
            },
            'city': self.city,
            'state': self.state,
            'phone': self.phone,
            'email': self.email,
            'hospitalId': self.hospital_id,
            'bloodInventory': self.get_inventory(),
            # Add direct blood group keys for frontend compatibility
            'a_positive': self.inventory_a_positive,
            'a_negative': self.inventory_a_negative,
            'b_positive': self.inventory_b_positive,
            'b_negative': self.inventory_b_negative,
            'ab_positive': self.inventory_ab_positive,
            'ab_negative': self.inventory_ab_negative,
            'o_positive': self.inventory_o_positive,
            'o_negative': self.inventory_o_negative,
            'is_24x7': True,  # Default for now
            'operatingHours': {
                'weekdays': self.operating_hours_weekdays,
                'weekends': self.operating_hours_weekends
            },
            'licenseNumber': self.license_number,
            'verified': self.verified,
            'lastInventoryUpdate': self.last_inventory_update.isoformat() if self.last_inventory_update else None
        }
