# Import all models for Flask-Migrate
from models.donor import Donor
from models.hospital import Hospital
from models.blood_bank import BloodBank
from models.blood_request import BloodRequest, BloodRequestMatch, Notification

__all__ = ['Donor', 'Hospital', 'BloodBank', 'BloodRequest', 'BloodRequestMatch', 'Notification']
