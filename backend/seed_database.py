"""
Database seed script with Indian government-style test data
Run after: flask db upgrade
"""
from app import create_app
from extensions import db
from models.donor import Donor
from models.hospital import Hospital
from models.blood_bank import BloodBank
from models.blood_request import BloodRequest, Notification
from datetime import datetime, timedelta
import random

def seed_database():
    """Seed database with realistic Indian data"""
    app = create_app()
    
    with app.app_context():
        print("🌱 Seeding database...")
        
        # Clear existing data
        print("Clearing existing data...")
        db.drop_all()
        db.create_all()
        
        # Indian cities with coordinates
        cities = {
            'Mumbai': {'latitude': 19.0760, 'longitude': 72.8777, 'state': 'Maharashtra'},
            'Delhi': {'latitude': 28.7041, 'longitude': 77.1025, 'state': 'Delhi'},
            'Bangalore': {'latitude': 12.9716, 'longitude': 77.5946, 'state': 'Karnataka'},
            'Hyderabad': {'latitude': 17.3850, 'longitude': 78.4867, 'state': 'Telangana'},
            'Chennai': {'latitude': 13.0827, 'longitude': 80.2707, 'state': 'Tamil Nadu'},
            'Kolkata': {'latitude': 22.5726, 'longitude': 88.3639, 'state': 'West Bengal'},
            'Pune': {'latitude': 18.5204, 'longitude': 73.8567, 'state': 'Maharashtra'},
            'Ahmedabad': {'latitude': 23.0225, 'longitude': 72.5714, 'state': 'Gujarat'}
        }
        
        blood_types = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
        
        # Create Donors (150 across India)
        print("Creating donors...")
        donor_names = [
            'Rajesh Kumar', 'Priya Sharma', 'Amit Patel', 'Sneha Reddy', 'Vijay Singh',
            'Anita Gupta', 'Rahul Verma', 'Neha Iyer', 'Suresh Nair', 'Pooja Deshmukh',
            'Arun Kumar', 'Kavita Rao', 'Manoj Joshi', 'Divya Menon', 'Sanjay Pillai',
            'Meera Bhat', 'Ravi Krishnan', 'Anjali Malhotra', 'Deepak Agarwal', 'Swati Banerjee'
        ]
        
        donors = []
        for i in range(150):
            city = random.choice(list(cities.keys()))
            city_data = cities[city]
            
            # Add small random offset to coordinates
            lat_offset = random.uniform(-0.1, 0.1)
            lon_offset = random.uniform(-0.1, 0.1)
            
            # Generate realistic donation count
            total_donations = random.randint(0, 50)
            
            donor = Donor(
                name=random.choice(donor_names),
                blood_type=random.choice(blood_types),
                phone=f"+91-{random.randint(7000000000, 9999999999)}",
                email=f"donor{i+1}@example.com",
                age=random.randint(18, 60),
                city=city,
                state=city_data['state'],
                street=f"{random.randint(1, 500)}, Sector {random.randint(1, 50)}",
                latitude=city_data['latitude'] + lat_offset,
                longitude=city_data['longitude'] + lon_offset,
                available_for_donation=random.choice([True, True, True, False]),
                last_donation_date=datetime.utcnow() - timedelta(days=random.randint(0, 365)),
                total_donations=total_donations,
                rating=round(random.uniform(4.0, 5.0), 1)
            )
            donors.append(donor)
        
        db.session.add_all(donors)
        db.session.commit()
        print(f"✅ Created {len(donors)} donors")
        
        # Create Government Hospitals
        print("Creating hospitals...")
        govt_hospitals = [
            # Delhi
            {'name': 'AIIMS Delhi', 'city': 'Delhi', 'type': 'Government', 'capacity': 2500},
            {'name': 'Safdarjung Hospital', 'city': 'Delhi', 'type': 'Government', 'capacity': 2200},
            {'name': 'Ram Manohar Lohia Hospital', 'city': 'Delhi', 'type': 'Government', 'capacity': 1800},
            {'name': 'Lady Hardinge Medical College', 'city': 'Delhi', 'type': 'Government', 'capacity': 1400},
            {'name': 'GTB Hospital', 'city': 'Delhi', 'type': 'Government', 'capacity': 1500},
            # Mumbai
            {'name': 'KEM Hospital', 'city': 'Mumbai', 'type': 'Government', 'capacity': 2000},
            {'name': 'Sion Hospital', 'city': 'Mumbai', 'type': 'Government', 'capacity': 1600},
            {'name': 'JJ Hospital', 'city': 'Mumbai', 'type': 'Government', 'capacity': 1800},
            {'name': 'Nair Hospital', 'city': 'Mumbai', 'type': 'Government', 'capacity': 1400},
            {'name': 'Rajawadi Hospital', 'city': 'Mumbai', 'type': 'Government', 'capacity': 1200},
            # Bangalore
            {'name': 'Victoria Hospital', 'city': 'Bangalore', 'type': 'Government', 'capacity': 1800},
            {'name': 'Bowring Hospital', 'city': 'Bangalore', 'type': 'Government', 'capacity': 1200},
            {'name': 'KC General Hospital', 'city': 'Bangalore', 'type': 'Government', 'capacity': 1400},
            {'name': 'Jayanagar General Hospital', 'city': 'Bangalore', 'type': 'Government', 'capacity': 1000},
            # Hyderabad
            {'name': 'Gandhi Hospital', 'city': 'Hyderabad', 'type': 'Government', 'capacity': 1500},
            {'name': 'Osmania General Hospital', 'city': 'Hyderabad', 'type': 'Government', 'capacity': 2000},
            {'name': 'Niloufer Hospital', 'city': 'Hyderabad', 'type': 'Government', 'capacity': 1200},
            # Chennai
            {'name': 'Government General Hospital', 'city': 'Chennai', 'type': 'Government', 'capacity': 2200},
            {'name': 'Stanley Medical College', 'city': 'Chennai', 'type': 'Government', 'capacity': 1800},
            {'name': 'Rajiv Gandhi Hospital', 'city': 'Chennai', 'type': 'Government', 'capacity': 1600},
            # Kolkata
            {'name': 'Medical College Kolkata', 'city': 'Kolkata', 'type': 'Government', 'capacity': 1600},
            {'name': 'SSKM Hospital', 'city': 'Kolkata', 'type': 'Government', 'capacity': 2000},
            {'name': 'RG Kar Medical College', 'city': 'Kolkata', 'type': 'Government', 'capacity': 1400},
            # Pune
            {'name': 'Sassoon Hospital', 'city': 'Pune', 'type': 'Government', 'capacity': 1400},
            {'name': 'YCM Hospital', 'city': 'Pune', 'type': 'Government', 'capacity': 1200},
            # Ahmedabad
            {'name': 'Civil Hospital', 'city': 'Ahmedabad', 'type': 'Government', 'capacity': 1200},
            {'name': 'LG Hospital', 'city': 'Ahmedabad', 'type': 'Government', 'capacity': 1000},
        ]
        
        private_hospitals = [
            # Delhi
            {'name': 'Apollo Hospital', 'city': 'Delhi', 'type': 'Private', 'capacity': 1000},
            {'name': 'Max Super Speciality Hospital', 'city': 'Delhi', 'type': 'Private', 'capacity': 900},
            {'name': 'Indraprastha Apollo', 'city': 'Delhi', 'type': 'Private', 'capacity': 850},
            {'name': 'Fortis Escorts Heart Institute', 'city': 'Delhi', 'type': 'Private', 'capacity': 800},
            {'name': 'Sir Ganga Ram Hospital', 'city': 'Delhi', 'type': 'Private', 'capacity': 750},
            # Mumbai
            {'name': 'Fortis Hospital', 'city': 'Mumbai', 'type': 'Private', 'capacity': 800},
            {'name': 'Lilavati Hospital', 'city': 'Mumbai', 'type': 'Private', 'capacity': 900},
            {'name': 'Jaslok Hospital', 'city': 'Mumbai', 'type': 'Private', 'capacity': 750},
            {'name': 'Breach Candy Hospital', 'city': 'Mumbai', 'type': 'Private', 'capacity': 700},
            {'name': 'Hinduja Hospital', 'city': 'Mumbai', 'type': 'Private', 'capacity': 850},
            # Bangalore
            {'name': 'Manipal Hospital', 'city': 'Bangalore', 'type': 'Private', 'capacity': 900},
            {'name': 'Apollo BGS Hospital', 'city': 'Bangalore', 'type': 'Private', 'capacity': 800},
            {'name': 'Fortis Hospital Bannerghatta', 'city': 'Bangalore', 'type': 'Private', 'capacity': 750},
            {'name': 'Columbia Asia Hospital', 'city': 'Bangalore', 'type': 'Private', 'capacity': 650},
            {'name': 'Narayana Health City', 'city': 'Bangalore', 'type': 'Private', 'capacity': 950},
            # Hyderabad
            {'name': 'KIMS Hospital', 'city': 'Hyderabad', 'type': 'Private', 'capacity': 700},
            {'name': 'Yashoda Hospital', 'city': 'Hyderabad', 'type': 'Private', 'capacity': 800},
            {'name': 'Care Hospital', 'city': 'Hyderabad', 'type': 'Private', 'capacity': 750},
            {'name': 'Apollo Hospital Jubilee Hills', 'city': 'Hyderabad', 'type': 'Private', 'capacity': 850},
            # Chennai
            {'name': 'Apollo Chennai', 'city': 'Chennai', 'type': 'Private', 'capacity': 950},
            {'name': 'Fortis Malar Hospital', 'city': 'Chennai', 'type': 'Private', 'capacity': 700},
            {'name': 'MIOT International', 'city': 'Chennai', 'type': 'Private', 'capacity': 800},
            {'name': 'Gleneagles Global Hospital', 'city': 'Chennai', 'type': 'Private', 'capacity': 750},
            # Kolkata
            {'name': 'Ruby Hospital', 'city': 'Kolkata', 'type': 'Private', 'capacity': 600},
            {'name': 'Apollo Gleneagles', 'city': 'Kolkata', 'type': 'Private', 'capacity': 750},
            {'name': 'Fortis Hospital', 'city': 'Kolkata', 'type': 'Private', 'capacity': 700},
            {'name': 'AMRI Hospital', 'city': 'Kolkata', 'type': 'Private', 'capacity': 650},
            # Pune
            {'name': 'Ruby Hall Clinic', 'city': 'Pune', 'type': 'Private', 'capacity': 700},
            {'name': 'Sahyadri Hospital', 'city': 'Pune', 'type': 'Private', 'capacity': 650},
            # Ahmedabad
            {'name': 'Sterling Hospital', 'city': 'Ahmedabad', 'type': 'Private', 'capacity': 600},
            {'name': 'Apollo Hospital', 'city': 'Ahmedabad', 'type': 'Private', 'capacity': 700},
        ]
        
        hospitals = []
        for hosp_data in govt_hospitals + private_hospitals:
            city_data = cities[hosp_data['city']]
            lat_offset = random.uniform(-0.05, 0.05)
            lon_offset = random.uniform(-0.05, 0.05)
            
            hospital = Hospital(
                name=hosp_data['name'],
                hospital_type=hosp_data['type'],
                city=hosp_data['city'],
                state=city_data['state'],
                latitude=city_data['latitude'] + lat_offset,
                longitude=city_data['longitude'] + lon_offset,
                street=f"{random.randint(1, 200)}, {random.choice(['MG Road', 'Anna Salai', 'Park Street', 'Linking Road'])}",
                phone=f"+91-{random.randint(1111111111, 9999999999)}",
                emergency_contact=f"+91-{random.randint(1111111111, 9999999999)}",
                email=f"{hosp_data['name'].lower().replace(' ', '.')}@hospital.gov.in",
                total_beds=hosp_data['capacity'],
                icu_beds=int(hosp_data['capacity'] * 0.1),
                has_blood_bank=random.choice([True, True, False]),
                website=f"http://{hosp_data['name'].lower().replace(' ', '')}.in"
            )
            hospitals.append(hospital)
        
        db.session.add_all(hospitals)
        db.session.commit()
        print(f"✅ Created {len(hospitals)} hospitals")
        
        # Create Blood Banks (attached to some hospitals)
        print("Creating blood banks...")
        blood_banks = []
        for hospital in hospitals:
            if hospital.has_blood_bank:
                blood_bank = BloodBank(
                    name=f"{hospital.name} Blood Bank",
                    hospital_id=hospital.id,
                    city=hospital.city,
                    state=hospital.state,
                    latitude=hospital.latitude,
                    longitude=hospital.longitude,
                    street=hospital.street,
                    phone=hospital.phone,
                    email=hospital.email.replace('@hospital', '@bloodbank') if hospital.email else None,
                    license_number=f"BB/{hospital.state[:3].upper()}/{random.randint(1000, 9999)}/20{random.randint(15, 24)}",
                    # Random inventory for each blood type
                    inventory_a_positive=random.randint(10, 100),
                    inventory_a_negative=random.randint(5, 50),
                    inventory_b_positive=random.randint(10, 100),
                    inventory_b_negative=random.randint(5, 50),
                    inventory_ab_positive=random.randint(5, 40),
                    inventory_ab_negative=random.randint(2, 20),
                    inventory_o_positive=random.randint(15, 120),
                    inventory_o_negative=random.randint(8, 60)
                )
                blood_banks.append(blood_bank)
        
        db.session.add_all(blood_banks)
        db.session.commit()
        print(f"✅ Created {len(blood_banks)} blood banks")
        
        # Create Blood Requests
        print("Creating blood requests...")
        patient_names = [
            'Ramesh Kumar', 'Sunita Devi', 'Anil Sharma', 'Geeta Patel', 'Sunil Reddy',
            'Lakshmi Iyer', 'Mohan Singh', 'Radha Krishnan', 'Vijay Kumar', 'Sita Gupta'
        ]
        
        blood_requests = []
        for i in range(30):
            hospital = random.choice(hospitals)
            urgency = random.choice(['Normal', 'Normal', 'Urgent', 'Critical'])
            
            req = BloodRequest(
                patient_name=random.choice(patient_names),
                blood_type=random.choice(blood_types),
                units_required=random.randint(1, 5),
                urgency=urgency,
                hospital_id=hospital.id,
                requester_name=f"Dr. {random.choice(['Kumar', 'Sharma', 'Patel', 'Reddy'])}",
                requester_phone=f"+91-{random.randint(7000000000, 9999999999)}",
                requester_email=f"doctor{i+1}@hospital.in",
                requester_relation='Doctor',
                latitude=hospital.latitude,
                longitude=hospital.longitude,
                reason=random.choice(['Surgery', 'Accident', 'Anemia', 'Thalassemia', 'Dengue']),
                required_by=datetime.utcnow() + timedelta(hours=random.randint(2, 72)),
                status=random.choice(['Pending', 'Pending', 'Matched', 'Fulfilled']),
                notes=f"Patient admitted in {hospital.name}"
            )
            blood_requests.append(req)
        
        db.session.add_all(blood_requests)
        db.session.commit()
        print(f"✅ Created {len(blood_requests)} blood requests")
        
        # Create some notifications
        print("Creating notifications...")
        notifications = []
        for i in range(20):
            donor = random.choice(donors)
            notif = Notification(
                recipient_id=donor.id,
                recipient_type='Donor',
                title=random.choice([
                    'Blood Request Near You',
                    'Emergency Blood Needed',
                    'Thank You for Donating',
                    'Donation Reminder'
                ]),
                message=f"A patient needs {random.choice(blood_types)} blood within 5km from your location.",
                notification_type=random.choice(['BloodRequest', 'DonationReminder', 'ThankYou']),
                priority=random.choice(['Low', 'Medium', 'High']),
                read=random.choice([True, False, False])
            )
            notifications.append(notif)
        
        db.session.add_all(notifications)
        db.session.commit()
        print(f"✅ Created {len(notifications)} notifications")
        
        # Print summary
        print("\n" + "="*60)
        print("🎉 DATABASE SEEDED SUCCESSFULLY!")
        print("="*60)
        print(f"📊 Summary:")
        print(f"   • {len(donors)} Donors across 8 cities")
        print(f"   • {len(hospitals)} Hospitals (Govt + Private)")
        print(f"   • {len(blood_banks)} Blood Banks with inventory")
        print(f"   • {len(blood_requests)} Blood Requests")
        print(f"   • {len(notifications)} Notifications")
        print("="*60)
        print("\n✅ You can now start the Flask server with: python app.py")
        print("🌐 API will be available at: http://localhost:5000")
        print("📋 Test endpoints:")
        print("   • GET  http://localhost:5000/api/health")
        print("   • GET  http://localhost:5000/api/donors")
        print("   • GET  http://localhost:5000/api/hospitals")
        print("   • GET  http://localhost:5000/api/blood-banks")
        print("   • POST http://localhost:5000/api/smart-match/find-donors")
        print("="*60 + "\n")

if __name__ == '__main__':
    seed_database()
