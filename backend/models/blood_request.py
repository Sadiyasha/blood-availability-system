from extensions import db
from datetime import datetime
from sqlalchemy.dialects.mysql import DECIMAL

class BloodRequest(db.Model):
    __tablename__ = 'blood_requests'
    
    id = db.Column(db.Integer, primary_key=True)
    patient_name = db.Column(db.String(100), nullable=False)
    blood_type = db.Column(db.Enum('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'), nullable=False)
    units_required = db.Column(db.Integer, nullable=False)
    urgency = db.Column(db.Enum('Critical', 'Urgent', 'Normal'), default='Normal')
    
    # Hospital
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'), nullable=False)
    
    # Requester contact
    requester_name = db.Column(db.String(100))
    requester_phone = db.Column(db.String(20))
    requester_email = db.Column(db.String(100))
    requester_relation = db.Column(db.String(50))
    
    # Location
    latitude = db.Column(DECIMAL(10, 8))
    longitude = db.Column(DECIMAL(11, 8))
    
    # Request details
    reason = db.Column(db.Text, nullable=False)
    status = db.Column(db.Enum('Pending', 'Matched', 'Fulfilled', 'Cancelled', 'Expired'), default='Pending')
    required_by = db.Column(db.DateTime, nullable=False)
    fulfilled_at = db.Column(db.DateTime)
    notes = db.Column(db.Text)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    hospital = db.relationship('Hospital', back_populates='blood_requests')
    matched_donors = db.relationship('BloodRequestMatch', back_populates='blood_request', lazy='dynamic')
    
    def to_dict(self):
        return {
            'id': self.id,
            'patientName': self.patient_name,
            'bloodType': self.blood_type,
            'unitsRequired': self.units_required,
            'urgency': self.urgency,
            'hospitalId': self.hospital_id,
            'requesterContact': {
                'name': self.requester_name,
                'phone': self.requester_phone,
                'email': self.requester_email,
                'relation': self.requester_relation
            },
            'location': {
                'latitude': float(self.latitude) if self.latitude else None,
                'longitude': float(self.longitude) if self.longitude else None
            },
            'reason': self.reason,
            'status': self.status,
            'requiredBy': self.required_by.isoformat() if self.required_by else None,
            'fulfilledAt': self.fulfilled_at.isoformat() if self.fulfilled_at else None,
            'notes': self.notes,
            'createdAt': self.created_at.isoformat() if self.created_at else None
        }


class BloodRequestMatch(db.Model):
    __tablename__ = 'blood_request_matches'
    
    id = db.Column(db.Integer, primary_key=True)
    blood_request_id = db.Column(db.Integer, db.ForeignKey('blood_requests.id'), nullable=False)
    donor_id = db.Column(db.Integer, db.ForeignKey('donors.id'), nullable=False)
    
    match_score = db.Column(DECIMAL(5, 2))
    distance_km = db.Column(DECIMAL(6, 2))
    notified = db.Column(db.Boolean, default=False)
    responded = db.Column(db.Boolean, default=False)
    response_time = db.Column(db.DateTime)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    blood_request = db.relationship('BloodRequest', back_populates='matched_donors')
    donor = db.relationship('Donor', back_populates='blood_requests')


class Notification(db.Model):
    __tablename__ = 'notifications'
    
    id = db.Column(db.Integer, primary_key=True)
    recipient_id = db.Column(db.Integer, nullable=False)
    recipient_type = db.Column(db.Enum('Donor', 'Hospital', 'User'), nullable=False)
    
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text, nullable=False)
    notification_type = db.Column(db.Enum('BloodRequest', 'Match', 'Reminder', 'Alert', 'Info', 'Emergency'), nullable=False)
    priority = db.Column(db.Enum('High', 'Medium', 'Low'), default='Medium')
    
    data = db.Column(db.Text)  # JSON string for additional data
    read = db.Column(db.Boolean, default=False)
    read_at = db.Column(db.DateTime)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'recipientId': self.recipient_id,
            'recipientType': self.recipient_type,
            'title': self.title,
            'message': self.message,
            'type': self.notification_type,
            'priority': self.priority,
            'read': self.read,
            'readAt': self.read_at.isoformat() if self.read_at else None,
            'createdAt': self.created_at.isoformat() if self.created_at else None
        }
