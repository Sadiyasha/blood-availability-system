"""
Rename blood bank records to remove the word 'Synthetic' from names.

Usage:
  python -m scripts.rename_synthetic_banks

This script updates DB entries so labels on the map no longer show
"Synthetic" — e.g., "Bangalore Synthetic Blood Bank 3" ->
"Bangalore Blood Bank 3".
"""
from app import create_app
from extensions import db
from models.blood_bank import BloodBank


def run():
    app = create_app()
    with app.app_context():
        banks = BloodBank.query.all()
        changed = 0
        for b in banks:
            if not b.name:
                continue
            name = str(b.name)
            if 'Synthetic' in name:
                new_name = name.replace('Synthetic Blood Bank', 'Blood Bank').replace('Synthetic', '').replace('  ', ' ').strip()
                if new_name != name:
                    b.name = new_name
                    changed += 1
        if changed:
            db.session.commit()
        print(f"Renamed {changed} blood bank(s).")


if __name__ == '__main__':
    run()
