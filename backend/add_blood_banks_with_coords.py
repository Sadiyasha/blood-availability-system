"""Add blood banks with city coordinates"""
from app import create_app, db
from models.blood_bank import BloodBank
import random

# City coordinates (approximate centers)
CITY_COORDS = {
    'Salem': (11.664325, 78.146011),
    'Hyderabad': (17.385044, 78.486671),
    'Lucknow': (26.846694, 80.946166),
    'Varanasi': (25.321684, 82.987289),
    'Mumbai': (19.075983, 72.877655),
    'Chennai': (13.082680, 80.270721),
    'Mysuru': (12.295810, 76.639381),
    'Durgapur': (23.520360, 87.311218),
    'Nashik': (19.997454, 73.789803),
    'Agra': (27.176670, 78.008072),
    'Nizamabad': (18.672314, 78.100555),
    'Howrah': (22.594389, 88.256180),
    'Siliguri': (26.727127, 88.395042),
    'Tirupati': (13.628545, 79.419229),
    'Karimnagar': (18.439214, 79.131241),
    'Kanpur': (26.449923, 80.331871),
    'Kolkata': (22.572645, 88.363892),
    'Coimbatore': (11.016844, 76.955832),
    'Bengaluru': (12.971599, 77.594566),
    'Madurai': (9.925201, 78.119774),
    'Vijayawada': (16.506174, 80.648015),
    'Mangaluru': (12.914142, 74.856201),
}

blood_banks_data = [
    {"name": "Apollo Blood Bank 123", "state": "Tamil Nadu", "city": "Salem", "address": "Salem Main Road, 161", "pincode": "139234", "contact": "066-450168", "mobile": "9211166611", "helpline": "1800-416", "email": "apollobloodbank123@gmail.com", "category": "Charity"},
    {"name": "Unity Blood Bank 145", "state": "Telangana", "city": "Hyderabad", "address": "Hyderabad Main Road, 165", "pincode": "157546", "contact": "051-531154", "mobile": "9786691404", "helpline": "1800-405", "email": "unitybloodbank145@gmail.com", "category": "Private"},
    {"name": "Red Cross Blood Bank 130", "state": "Uttar Pradesh", "city": "Lucknow", "address": "Lucknow Main Road, 187", "pincode": "155844", "contact": "042-318790", "mobile": "9865613672", "helpline": "1800-836", "email": "redcrossbloodbank130@gmail.com", "category": "Charity"},
    {"name": "Sanjeevani Blood Bank 43", "state": "Uttar Pradesh", "city": "Varanasi", "address": "Varanasi Main Road, 77", "pincode": "181540", "contact": "059-239328", "mobile": "9450080640", "helpline": "1800-713", "email": "sanjeevanibloodbank43@gmail.com", "category": "Private"},
    {"name": "Jeevan Blood Bank 85", "state": "Maharashtra", "city": "Mumbai", "address": "Mumbai Main Road, 163", "pincode": "167828", "contact": "083-119635", "mobile": "9673752849", "helpline": "1800-213", "email": "jeevanbloodbank85@gmail.com", "category": "Charity"},
    {"name": "Sanjeevani Blood Bank 50", "state": "Tamil Nadu", "city": "Chennai", "address": "Chennai Main Road, 171", "pincode": "128312", "contact": "076-712722", "mobile": "9139249346", "helpline": "1800-180", "email": "sanjeevanibloodbank50@gmail.com", "category": "Government"},
    {"name": "LifeCare Blood Bank 67", "state": "Karnataka", "city": "Mysuru", "address": "Mysuru Main Road, 71", "pincode": "167426", "contact": "066-148394", "mobile": "9779585781", "helpline": "1800-981", "email": "lifecarebloodbank67@gmail.com", "category": "Private"},
    {"name": "Sanjeevani Blood Bank 27", "state": "West Bengal", "city": "Durgapur", "address": "Durgapur Main Road, 152", "pincode": "135994", "contact": "080-367459", "mobile": "9107111903", "helpline": "1800-865", "email": "sanjeevanibloodbank27@gmail.com", "category": "Private"},
    {"name": "Red Cross Blood Bank 144", "state": "Karnataka", "city": "Mysuru", "address": "Mysuru Main Road, 157", "pincode": "169590", "contact": "029-332629", "mobile": "9956687958", "helpline": "1800-615", "email": "redcrossbloodbank144@gmail.com", "category": "Private"},
    {"name": "Hope Blood Bank 89", "state": "Maharashtra", "city": "Nashik", "address": "Nashik Main Road, 187", "pincode": "152719", "contact": "034-310846", "mobile": "9537332815", "helpline": "1800-643", "email": "hopebloodbank89@gmail.com", "category": "Private"},
    {"name": "LifeCare Blood Bank 132", "state": "Uttar Pradesh", "city": "Agra", "address": "Agra Main Road, 27", "pincode": "170526", "contact": "049-546370", "mobile": "9803191354", "helpline": "1800-688", "email": "lifecarebloodbank132@gmail.com", "category": "Private"},
    {"name": "Jeevan Blood Bank 42", "state": "Karnataka", "city": "Mysuru", "address": "Mysuru Main Road, 29", "pincode": "179750", "contact": "030-597077", "mobile": "9601333569", "helpline": "1800-773", "email": "jeevanbloodbank42@gmail.com", "category": "Private"},
    {"name": "Red Cross Blood Bank 183", "state": "West Bengal", "city": "Durgapur", "address": "Durgapur Main Road, 107", "pincode": "124115", "contact": "058-954230", "mobile": "9833239207", "helpline": "1800-748", "email": "redcrossbloodbank183@gmail.com", "category": "Private"},
    {"name": "Unity Blood Bank 64", "state": "Telangana", "city": "Nizamabad", "address": "Nizamabad Main Road, 190", "pincode": "139297", "contact": "011-760255", "mobile": "9162103837", "helpline": "1800-998", "email": "unitybloodbank64@gmail.com", "category": "Government"},
    {"name": "Unity Blood Bank 123", "state": "Maharashtra", "city": "Mumbai", "address": "Mumbai Main Road, 198", "pincode": "170660", "contact": "079-962142", "mobile": "9920728997", "helpline": "1800-426", "email": "unitybloodbank123@gmail.com", "category": "Charity"},
    {"name": "Unity Blood Bank 96", "state": "Uttar Pradesh", "city": "Lucknow", "address": "Lucknow Main Road, 118", "pincode": "154969", "contact": "051-570505", "mobile": "9865385376", "helpline": "1800-518", "email": "unitybloodbank96@gmail.com", "category": "Private"},
    {"name": "LifeCare Blood Bank 80", "state": "Tamil Nadu", "city": "Salem", "address": "Salem Main Road, 130", "pincode": "115358", "contact": "051-320389", "mobile": "9836713622", "helpline": "1800-571", "email": "lifecarebloodbank80@gmail.com", "category": "Charity"},
    {"name": "Red Cross Blood Bank 122", "state": "Uttar Pradesh", "city": "Varanasi", "address": "Varanasi Main Road, 101", "pincode": "177044", "contact": "075-583712", "mobile": "9957836931", "helpline": "1800-114", "email": "redcrossbloodbank122@gmail.com", "category": "Private"},
    {"name": "Jeevan Blood Bank 36", "state": "Tamil Nadu", "city": "Chennai", "address": "Chennai Main Road, 66", "pincode": "171548", "contact": "045-376805", "mobile": "9761414358", "helpline": "1800-252", "email": "jeevanbloodbank36@gmail.com", "category": "Government"},
    {"name": "Unity Blood Bank 8", "state": "Uttar Pradesh", "city": "Lucknow", "address": "Lucknow Main Road, 183", "pincode": "199678", "contact": "073-198895", "mobile": "9736548808", "helpline": "1800-426", "email": "unitybloodbank8@gmail.com", "category": "Charity"},
    {"name": "Jeevan Blood Bank 187", "state": "Andhra Pradesh", "city": "Tirupati", "address": "Tirupati Main Road, 61", "pincode": "121619", "contact": "012-631981", "mobile": "9923305098", "helpline": "1800-507", "email": "jeevanbloodbank187@gmail.com", "category": "Government"},
    {"name": "Hope Blood Bank 51", "state": "West Bengal", "city": "Howrah", "address": "Howrah Main Road, 108", "pincode": "161895", "contact": "025-187422", "mobile": "9702077830", "helpline": "1800-227", "email": "hopebloodbank51@gmail.com", "category": "Charity"},
    {"name": "Sanjeevani Blood Bank 55", "state": "West Bengal", "city": "Siliguri", "address": "Siliguri Main Road, 117", "pincode": "150019", "contact": "065-182475", "mobile": "9171167243", "helpline": "1800-997", "email": "sanjeevanibloodbank55@gmail.com", "category": "Government"},
    {"name": "Jeevan Blood Bank 148", "state": "Telangana", "city": "Nizamabad", "address": "Nizamabad Main Road, 197", "pincode": "117025", "contact": "092-942436", "mobile": "9476555705", "helpline": "1800-618", "email": "jeevanbloodbank148@gmail.com", "category": "Government"},
    {"name": "Jeevan Blood Bank 112", "state": "Telangana", "city": "Karimnagar", "address": "Karimnagar Main Road, 3", "pincode": "180708", "contact": "034-678775", "mobile": "9408324142", "helpline": "1800-480", "email": "jeevanbloodbank112@gmail.com", "category": "Charity"},
    {"name": "Apollo Blood Bank 31", "state": "Uttar Pradesh", "city": "Kanpur", "address": "Kanpur Main Road, 25", "pincode": "122920", "contact": "073-728418", "mobile": "9655550012", "helpline": "1800-709", "email": "apollobloodbank31@gmail.com", "category": "Government"},
    {"name": "Sanjeevani Blood Bank 175", "state": "Andhra Pradesh", "city": "Tirupati", "address": "Tirupati Main Road, 110", "pincode": "157516", "contact": "097-918093", "mobile": "9850980364", "helpline": "1800-664", "email": "sanjeevanibloodbank175@gmail.com", "category": "Private"},
    {"name": "Apollo Blood Bank 152", "state": "Maharashtra", "city": "Mumbai", "address": "Mumbai Main Road, 62", "pincode": "195907", "contact": "069-271553", "mobile": "9892016997", "helpline": "1800-920", "email": "apollobloodbank152@gmail.com", "category": "Government"},
    {"name": "Red Cross Blood Bank 91", "state": "Uttar Pradesh", "city": "Agra", "address": "Agra Main Road, 67", "pincode": "147105", "contact": "089-144490", "mobile": "9803511665", "helpline": "1800-295", "email": "redcrossbloodbank91@gmail.com", "category": "Private"},
    {"name": "Unity Blood Bank 30", "state": "West Bengal", "city": "Kolkata", "address": "Kolkata Main Road, 165", "pincode": "162428", "contact": "056-425928", "mobile": "9535375796", "helpline": "1800-444", "email": "unitybloodbank30@gmail.com", "category": "Government"},
    {"name": "Sanjeevani Blood Bank 129", "state": "Andhra Pradesh", "city": "Tirupati", "address": "Tirupati Main Road, 117", "pincode": "186015", "contact": "085-635778", "mobile": "9418350659", "helpline": "1800-632", "email": "sanjeevanibloodbank129@gmail.com", "category": "Government"},
    {"name": "Apollo Blood Bank 99", "state": "Telangana", "city": "Karimnagar", "address": "Karimnagar Main Road, 18", "pincode": "148748", "contact": "027-741315", "mobile": "9913905124", "helpline": "1800-152", "email": "apollobloodbank99@gmail.com", "category": "Charity"},
    {"name": "LifeCare Blood Bank 138", "state": "Tamil Nadu", "city": "Chennai", "address": "Chennai Main Road, 136", "pincode": "168343", "contact": "081-636217", "mobile": "9303291855", "helpline": "1800-227", "email": "lifecarebloodbank138@gmail.com", "category": "Private"},
    {"name": "Jeevan Blood Bank 140", "state": "Tamil Nadu", "city": "Coimbatore", "address": "Coimbatore Main Road, 28", "pincode": "189081", "contact": "080-840691", "mobile": "9316812695", "helpline": "1800-643", "email": "jeevanbloodbank140@gmail.com", "category": "Government"},
    {"name": "Apollo Blood Bank 2", "state": "Uttar Pradesh", "city": "Agra", "address": "Agra Main Road, 171", "pincode": "163636", "contact": "015-550080", "mobile": "9793876158", "helpline": "1800-854", "email": "apollobloodbank2@gmail.com", "category": "Private"},
    {"name": "LifeCare Blood Bank 99", "state": "Uttar Pradesh", "city": "Varanasi", "address": "Varanasi Main Road, 140", "pincode": "147159", "contact": "087-115467", "mobile": "9225744768", "helpline": "1800-340", "email": "lifecarebloodbank99@gmail.com", "category": "Government"},
    {"name": "Apollo Blood Bank 109", "state": "Tamil Nadu", "city": "Chennai", "address": "Chennai Main Road, 115", "pincode": "115575", "contact": "097-486286", "mobile": "9915670551", "helpline": "1800-313", "email": "apollobloodbank109@gmail.com", "category": "Private"},
    {"name": "Apollo Blood Bank 144", "state": "Tamil Nadu", "city": "Chennai", "address": "Chennai Main Road, 92", "pincode": "150869", "contact": "068-107966", "mobile": "9938547116", "helpline": "1800-668", "email": "apollobloodbank144@gmail.com", "category": "Government"},
    {"name": "Red Cross Blood Bank 85", "state": "Karnataka", "city": "Bengaluru", "address": "Bengaluru Main Road, 103", "pincode": "169828", "contact": "066-339317", "mobile": "9368731379", "helpline": "1800-630", "email": "redcrossbloodbank85@gmail.com", "category": "Government"},
    {"name": "Apollo Blood Bank 89", "state": "Tamil Nadu", "city": "Coimbatore", "address": "Coimbatore Main Road, 8", "pincode": "127168", "contact": "011-940290", "mobile": "9884738404", "helpline": "1800-661", "email": "apollobloodbank89@gmail.com", "category": "Charity"},
    {"name": "Sanjeevani Blood Bank 48", "state": "Tamil Nadu", "city": "Madurai", "address": "Madurai Main Road, 17", "pincode": "131891", "contact": "060-347650", "mobile": "9264348813", "helpline": "1800-737", "email": "sanjeevanibloodbank48@gmail.com", "category": "Charity"},
    {"name": "Red Cross Blood Bank 62", "state": "Uttar Pradesh", "city": "Agra", "address": "Agra Main Road, 38", "pincode": "184198", "contact": "046-210476", "mobile": "9217629852", "helpline": "1800-139", "email": "redcrossbloodbank62@gmail.com", "category": "Private"},
    {"name": "Unity Blood Bank 176", "state": "Andhra Pradesh", "city": "Vijayawada", "address": "Vijayawada Main Road, 194", "pincode": "157474", "contact": "014-486400", "mobile": "9418338184", "helpline": "1800-476", "email": "unitybloodbank176@gmail.com", "category": "Private"},
    {"name": "LifeCare Blood Bank 39", "state": "Maharashtra", "city": "Nashik", "address": "Nashik Main Road, 110", "pincode": "187311", "contact": "048-217849", "mobile": "9527736986", "helpline": "1800-586", "email": "lifecarebloodbank39@gmail.com", "category": "Charity"},
    {"name": "Hope Blood Bank 100", "state": "West Bengal", "city": "Siliguri", "address": "Siliguri Main Road, 13", "pincode": "182878", "contact": "070-421435", "mobile": "9794366288", "helpline": "1800-566", "email": "hopebloodbank100@gmail.com", "category": "Private"},
    {"name": "Red Cross Blood Bank 62", "state": "Uttar Pradesh", "city": "Varanasi", "address": "Varanasi Main Road, 64", "pincode": "160972", "contact": "073-974591", "mobile": "9648941249", "helpline": "1800-920", "email": "redcrossbloodbank62@gmail.com", "category": "Private"},
    {"name": "Hope Blood Bank 100", "state": "Andhra Pradesh", "city": "Tirupati", "address": "Tirupati Main Road, 76", "pincode": "182442", "contact": "045-185339", "mobile": "9412680969", "helpline": "1800-485", "email": "hopebloodbank100@gmail.com", "category": "Government"},
    {"name": "Hope Blood Bank 199", "state": "Karnataka", "city": "Mangaluru", "address": "Mangaluru Main Road, 156", "pincode": "187073", "contact": "083-540750", "mobile": "9520125773", "helpline": "1800-477", "email": "hopebloodbank199@gmail.com", "category": "Charity"},
    {"name": "Hope Blood Bank 122", "state": "Karnataka", "city": "Bengaluru", "address": "Bengaluru Main Road, 169", "pincode": "182911", "contact": "043-408556", "mobile": "9873553072", "helpline": "1800-473", "email": "hopebloodbank122@gmail.com", "category": "Private"},
    {"name": "Unity Blood Bank 55", "state": "Telangana", "city": "Karimnagar", "address": "Karimnagar Main Road, 141", "pincode": "189945", "contact": "051-894728", "mobile": "9533209021", "helpline": "1800-101", "email": "unitybloodbank55@gmail.com", "category": "Charity"},
]

def add_blood_banks():
    app = create_app()
    with app.app_context():
        added = 0
        skipped = 0
        
        for bank_data in blood_banks_data:
            city = bank_data['city']
            
            if city not in CITY_COORDS:
                print(f"⚠️  Skipping {bank_data['name']} - no coordinates for {city}")
                skipped += 1
                continue
            
            # Get base coordinates for the city
            base_lat, base_lon = CITY_COORDS[city]
            
            # Add small random offset for each blood bank (within ~2km radius)
            lat_offset = random.uniform(-0.015, 0.015)
            lon_offset = random.uniform(-0.015, 0.015)
            
            bb = BloodBank(
                name=bank_data['name'],
                latitude=base_lat + lat_offset,
                longitude=base_lon + lon_offset,
                street=bank_data['address'],
                city=city,
                state=bank_data['state'],
                pincode=bank_data['pincode'],
                country='India',
                phone=bank_data['contact'],
                email=bank_data['email'],
                # Random inventory between 0-50 units
                inventory_a_positive=random.randint(0, 50),
                inventory_a_negative=random.randint(0, 30),
                inventory_b_positive=random.randint(0, 50),
                inventory_b_negative=random.randint(0, 30),
                inventory_ab_positive=random.randint(0, 25),
                inventory_ab_negative=random.randint(0, 15),
                inventory_o_positive=random.randint(0, 60),
                inventory_o_negative=random.randint(0, 30),
                verified=True
            )
            
            db.session.add(bb)
            added += 1
            print(f"✅ Added: {bank_data['name']} in {city}")
        
        db.session.commit()
        print(f"\n🎉 Import complete!")
        print(f"   Added: {added}")
        print(f"   Skipped: {skipped}")

if __name__ == '__main__':
    add_blood_banks()
