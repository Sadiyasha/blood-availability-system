"""
Add synthetic blood banks per city to ensure the map shows counts.
Run after `flask db upgrade` or when the app DB is available.

Usage:
  python add_city_bloodbanks.py

This script will create up to `TARGET_PER_CITY` blood banks per city
if the current count is lower, using small randomized coordinate offsets.
"""
from app import create_app
from extensions import db
from models.blood_bank import BloodBank
from datetime import datetime
import random


def ensure_banks(target_per_city=8):
    app = create_app()
    with app.app_context():
        cities = {
            'Bangalore': {'latitude': 12.9716, 'longitude': 77.5946, 'state': 'Karnataka'},
            'Mumbai': {'latitude': 19.0760, 'longitude': 72.8777, 'state': 'Maharashtra'},
            'Delhi': {'latitude': 28.7041, 'longitude': 77.1025, 'state': 'Delhi'},
            'Hyderabad': {'latitude': 17.3850, 'longitude': 78.4867, 'state': 'Telangana'},
            'Chennai': {'latitude': 13.0827, 'longitude': 80.2707, 'state': 'Tamil Nadu'},
            'Kolkata': {'latitude': 22.5726, 'longitude': 88.3639, 'state': 'West Bengal'},
            'Pune': {'latitude': 18.5204, 'longitude': 73.8567, 'state': 'Maharashtra'},
            'Ahmedabad': {'latitude': 23.0225, 'longitude': 72.5714, 'state': 'Gujarat'},
        }

        created = 0
        for city, meta in cities.items():
            count = BloodBank.query.filter(BloodBank.city == city).count()
            need = max(0, target_per_city - count)
            print(f"{city}: existing={count}, need={need}")
            for i in range(need):
                lat_off = random.uniform(-0.03, 0.03)
                lon_off = random.uniform(-0.03, 0.03)
                bb = BloodBank(
                    name=f"{city} Synthetic Blood Bank {count + i + 1}",
                    latitude=meta['latitude'] + lat_off,
                    longitude=meta['longitude'] + lon_off,
                    street=f"{random.randint(1,200)}, Synthetic St",
                    city=city,
                    state=meta['state'],
                    phone=f"+91-{random.randint(6000000000, 9999999999)}",
                    email=f"bloodbank{city.lower()}{count+i+1}@example.org",
                    license_number=f"BB/{meta['state'][:3].upper()}/{random.randint(1000,9999)}/2025",
                    inventory_a_positive=random.randint(5, 80),
                    inventory_a_negative=random.randint(0, 40),
                    inventory_b_positive=random.randint(5, 80),
                    inventory_b_negative=random.randint(0, 40),
                    inventory_ab_positive=random.randint(0, 30),
                    inventory_ab_negative=random.randint(0, 20),
                    inventory_o_positive=random.randint(10, 120),
                    inventory_o_negative=random.randint(2, 60),
                    verified=True,
                    last_inventory_update=datetime.utcnow()
                )
                db.session.add(bb)
                created += 1

        if created:
            db.session.commit()
        print(f"Created {created} synthetic blood banks.")


if __name__ == '__main__':
    ensure_banks()
