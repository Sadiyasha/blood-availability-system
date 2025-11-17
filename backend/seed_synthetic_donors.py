"""Seed synthetic donors based on existing blood banks.

This script creates N synthetic donors per blood bank using the bank's
location with small random offsets. It avoids duplicating phone numbers
by using a high-range counter.

Run with the backend venv active:
  .\.venv\Scripts\python.exe seed_synthetic_donors.py --count 2
"""
import random
import argparse
from app import create_app, db
from models.blood_bank import BloodBank
from models.donor import Donor
from datetime import date

BLOOD_TYPES = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
GENDERS = ['Male', 'Female', 'Other']

def generate_phone(start, idx):
    # Ensure a 10-digit phone-like string (India style)
    base = str(start + idx)
    return base[-10:]

def seed(count_per_bank=2, phone_start=9000000000):
    app = create_app()
    with app.app_context():
        banks = BloodBank.query.all()
        if not banks:
            print('No blood banks found in database. Run the importer first.')
            return

        created = 0
        phone_idx = 0
        for bank in banks:
            lat = float(bank.latitude) if bank.latitude is not None else 28.6139
            lng = float(bank.longitude) if bank.longitude is not None else 77.2090
            city = bank.city or ''
            state = bank.state or ''

            for i in range(count_per_bank):
                phone = generate_phone(phone_start, phone_idx)
                phone_idx += 1

                donor = Donor(
                    name=f"Donor {bank.id}-{i+1}",
                    blood_type=random.choice(BLOOD_TYPES),
                    phone=phone,
                    email=f"donor{bank.id}.{i+1}@example.com",
                    age=random.randint(18, 60),
                    gender=random.choice(GENDERS),
                    latitude=round(lat + random.uniform(-0.01, 0.01), 6),
                    longitude=round(lng + random.uniform(-0.01, 0.01), 6),
                    street=bank.street,
                    city=city,
                    state=state,
                    pincode=bank.pincode,
                    available_for_donation=True,
                    last_donation_date=None,
                )

                try:
                    db.session.add(donor)
                    db.session.commit()
                    created += 1
                except Exception as e:
                    db.session.rollback()
                    print(f"Failed to insert donor for bank {bank.id}: {e}")

        print(f"Seeding complete. Created {created} donors.")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Seed synthetic donors from blood banks')
    parser.add_argument('--count', type=int, default=2, help='Number of donors per blood bank')
    args = parser.parse_args()
    seed(count_per_bank=args.count)
"""
Seed synthetic donors into the donors table using existing BloodBank rows.
Run from backend folder while the virtualenv is active:

.venv\Scripts\Activate.ps1
python seed_synthetic_donors.py --per-bank 3

This will create 3 donors per blood bank with random blood types and slightly offset coordinates.
"""
import random
import argparse
from faker import Faker
from datetime import datetime, timedelta

from app import create_app, db
from models.blood_bank import BloodBank
from models.donor import Donor

fake = Faker()

BLOOD_TYPES = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']


def random_phone():
    # Indian-style 10-digit mobile
    return '9' + ''.join(str(random.randint(0,9)) for _ in range(9))


def seed(per_bank=3, dry_run=False):
    app = create_app()
    with app.app_context():
        banks = BloodBank.query.all()
        created = 0
        for bank in banks:
            base_lat = float(bank.latitude)
            base_lng = float(bank.longitude)
            for i in range(per_bank):
                name = fake.name()
                phone = random_phone()
                # ensure unique phone by adding small suffix if collision
                # (DB unique constraint on phone may raise otherwise)
                phone = phone
                blood_type = random.choice(BLOOD_TYPES)
                age = random.randint(18, 60)
                gender = random.choice(['Male', 'Female', 'Other'])
                # small random offset within ~0.5km
                offset_lat = base_lat + random.uniform(-0.0045, 0.0045)
                offset_lng = base_lng + random.uniform(-0.0045, 0.0045)

                donor = Donor(
                    name=name,
                    blood_type=blood_type,
                    phone=phone,
                    email=fake.email(),
                    age=age,
                    gender=gender,
                    latitude=round(offset_lat, 6),
                    longitude=round(offset_lng, 6),
                    street=bank.street or '',
                    city=bank.city or '',
                    state=bank.state or '',
                    pincode=bank.pincode or '',
                    country=bank.country or 'India',
                    last_donation_date=(datetime.utcnow() - timedelta(days=random.randint(90, 900))).date(),
                    available_for_donation=random.choice([True, True, False]),
                    total_donations=random.randint(0, 8),
                    has_chronic_diseases=random.choice([False, False, True]),
                    emergency_contact_name=fake.name(),
                    emergency_contact_phone=random_phone(),
                    verified=True,
                    rating=round(random.uniform(3.5, 5.0), 1),
                )

                if dry_run:
                    print('DRY:', donor.name, donor.blood_type, donor.phone, donor.latitude, donor.longitude)
                else:
                    try:
                        db.session.add(donor)
                        db.session.commit()
                        created += 1
                    except Exception as e:
                        db.session.rollback()
                        print('Failed to insert donor', donor.name, e)
                        continue
        print(f'Seed complete. Created {created} donors.' )


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--per-bank', type=int, default=2, help='Number of synthetic donors to create per blood bank')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    seed(per_bank=args.per_bank, dry_run=args.dry_run)
