"""
Import blood bank CSV data into the application's database.

Usage:
  # from a local file
  python import_blood_banks.py --file path/to/blood_banks.csv

  # or download from a URL
  python import_blood_banks.py --url "https://example.com/blood_banks.csv"

Options:
  --dry-run    Parse and show summary but don't insert into DB

The script attempts to map common CSV column names to the `BloodBank` model fields.
"""
import argparse
import csv
import sys
import tempfile
import requests
from decimal import Decimal

from app import create_app, db
from models.blood_bank import BloodBank


COMMON_LAT_KEYS = ('latitude', 'lat', 'lattitude', 'geo_lat')
COMMON_LON_KEYS = ('longitude', 'lon', 'lng', 'long', 'geo_lon')
COMMON_NAME_KEYS = ('name', 'blood_bank_name', 'hospital_name')
COMMON_PHONE_KEYS = ('phone', 'phone_number', 'contact')
COMMON_EMAIL_KEYS = ('email', 'email_id', 'contact_email')
COMMON_CITY_KEYS = ('city', 'town')
COMMON_STATE_KEYS = ('state', 'region')
COMMON_STREET_KEYS = ('street', 'address', 'address_line')
COMMON_PIN_KEYS = ('pincode', 'pin', 'zipcode', 'postalcode')


def find_key(row_keys, candidates):
    for c in candidates:
        if c in row_keys:
            return c
    # try fuzzy: any key that contains candidate substring
    for c in candidates:
        for k in row_keys:
            if c in k:
                return k
    return None


def parse_int(value):
    try:
        return int(float(value))
    except Exception:
        return 0


def parse_decimal(value):
    try:
        return Decimal(str(value))
    except Exception:
        return None


def import_from_csv(path_or_fileobj, dry_run=False):
    if hasattr(path_or_fileobj, 'read'):
        fh = path_or_fileobj
    else:
        fh = open(path_or_fileobj, 'r', encoding='utf-8')

    reader = csv.DictReader(fh)
    keys = [k.strip().lower() for k in reader.fieldnames]

    # column discovery
    name_k = find_key(keys, COMMON_NAME_KEYS)
    lat_k = find_key(keys, COMMON_LAT_KEYS)
    lon_k = find_key(keys, COMMON_LON_KEYS)
    phone_k = find_key(keys, COMMON_PHONE_KEYS)
    email_k = find_key(keys, COMMON_EMAIL_KEYS)
    city_k = find_key(keys, COMMON_CITY_KEYS)
    state_k = find_key(keys, COMMON_STATE_KEYS)
    street_k = find_key(keys, COMMON_STREET_KEYS)
    pin_k = find_key(keys, COMMON_PIN_KEYS)

    inventory_map = {
        'inventory_a_positive': ('a_pos', 'a_positive', 'a+', 'a_positive_inventory'),
        'inventory_a_negative': ('a_neg', 'a_negative', 'a-'),
        'inventory_b_positive': ('b_pos', 'b_positive', 'b+'),
        'inventory_b_negative': ('b_neg', 'b_negative', 'b-'),
        'inventory_ab_positive': ('ab_pos', 'ab_positive', 'ab+'),
        'inventory_ab_negative': ('ab_neg', 'ab_negative', 'ab-'),
        'inventory_o_positive': ('o_pos', 'o_positive', 'o+'),
        'inventory_o_negative': ('o_neg', 'o_negative', 'o-')
    }

    # map discovered inventory keys
    inv_keys = {}
    for model_field, candidates in inventory_map.items():
        found = find_key(keys, candidates)
        inv_keys[model_field] = found

    created = 0
    skipped = 0

    app = create_app()
    with app.app_context():
        for row in reader:
            # normalize row keys to lowercase
            row_l = {k.strip().lower(): (v.strip() if v is not None else '') for k, v in row.items()}

            name = row_l.get(name_k, '') if name_k else (row_l.get('name') or '')
            phone = row_l.get(phone_k, '') if phone_k else ''
            email = row_l.get(email_k, '') if email_k else ''
            city = row_l.get(city_k, '') if city_k else ''
            state = row_l.get(state_k, '') if state_k else ''
            street = row_l.get(street_k, '') if street_k else ''
            pincode = row_l.get(pin_k, '') if pin_k else ''

            lat = parse_decimal(row_l.get(lat_k, '')) if lat_k else None
            lon = parse_decimal(row_l.get(lon_k, '')) if lon_k else None

            if not name:
                skipped += 1
                continue

            bb = BloodBank(
                name=name,
                phone=phone or 'N/A',
                email=email or None,
                city=city or None,
                state=state or None,
                street=street or None,
                pincode=pincode or None,
                country='India'
            )

            if lat is not None:
                try:
                    bb.latitude = float(lat)
                except Exception:
                    bb.latitude = None
            if lon is not None:
                try:
                    bb.longitude = float(lon)
                except Exception:
                    bb.longitude = None

            # inventory
            for model_field, csv_key in inv_keys.items():
                if csv_key:
                    setattr(bb, model_field, parse_int(row_l.get(csv_key, 0)))

            if dry_run:
                print('DRY:', bb.to_dict())
            else:
                db.session.add(bb)
                created += 1

        if not dry_run:
            db.session.commit()

    if not hasattr(path_or_fileobj, 'read'):
        fh.close()

    print('\nImport complete:')
    print(f'  created: {created}')
    print(f'  skipped (missing name): {skipped}')


def download_to_temp(url):
    print(f'Downloading: {url}')
    resp = requests.get(url, stream=True, timeout=30)
    resp.raise_for_status()
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix='.csv', mode='w', encoding='utf-8')
    # write content in text chunks
    for chunk in resp.iter_lines(decode_unicode=True):
        if chunk:
            tmp.write(chunk + '\n')
    tmp.flush()
    tmp.close()
    return tmp.name


def main():
    parser = argparse.ArgumentParser(description='Import blood bank CSV into app DB')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--file', help='Local CSV file path')
    group.add_argument('--url', help='Remote CSV URL to download')
    parser.add_argument('--dry-run', action='store_true', help='Parse and show without inserting')

    args = parser.parse_args()

    try:
        if args.url:
            path = download_to_temp(args.url)
            import_from_csv(path, dry_run=args.dry_run)
        else:
            import_from_csv(args.file, dry_run=args.dry_run)
    except Exception as e:
        print('Error during import:', e)
        sys.exit(1)


if __name__ == '__main__':
    main()
