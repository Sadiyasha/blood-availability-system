from flask import Blueprint, request, jsonify
from extensions import db
from models.blood_bank import BloodBank
from services.google_maps_service import maps_service

blood_bank_bp = Blueprint('blood_banks', __name__)

@blood_bank_bp.route('/', methods=['GET'])
def get_blood_banks():
    """Get all blood banks"""
    try:
        from models.donor import Donor
        from sqlalchemy import or_
        
        city = request.args.get('city')
        state = request.args.get('state')
        limit = int(request.args.get('limit', 50))
        
        query = BloodBank.query
        
        if city:
            query = query.filter(BloodBank.city.ilike(f'%{city}%'))
        if state:
            query = query.filter(BloodBank.state.ilike(f'%{state}%'))
        
        blood_banks = query.limit(limit).all()
        
        # City name variations mapping
        city_variations = {
            'bengaluru': ['bengaluru', 'bangalore'],
            'bangalore': ['bengaluru', 'bangalore'],
            'mumbai': ['mumbai', 'bombay'],
            'bombay': ['mumbai', 'bombay'],
            'chennai': ['chennai', 'madras'],
            'madras': ['chennai', 'madras'],
            'kolkata': ['kolkata', 'calcutta'],
            'calcutta': ['kolkata', 'calcutta'],
        }
        
        # Enrich with donor names from the same city
        result_data = []
        for bb in blood_banks:
            bb_dict = bb.to_dict()
            
            # Find available donors in the same city (handle city name variations)
            if bb.city:
                city_lower = bb.city.lower()
                search_cities = city_variations.get(city_lower, [city_lower])
                
                # Build OR condition for city variations
                city_conditions = [Donor.city.ilike(f'%{c}%') for c in search_cities]
                
                donors = Donor.query.filter(
                    or_(*city_conditions),
                    Donor.available_for_donation == True
                ).limit(10).all()
                
                bb_dict['donor_names'] = [d.name for d in donors]
                bb_dict['donor_count'] = len(donors)
            else:
                bb_dict['donor_names'] = []
                bb_dict['donor_count'] = 0
            
            result_data.append(bb_dict)
        
        return jsonify({
            'success': True,
            'count': len(result_data),
            'data': result_data
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@blood_bank_bp.route('/<int:blood_bank_id>', methods=['GET'])
def get_blood_bank(blood_bank_id):
    """Get blood bank by ID"""
    try:
        blood_bank = BloodBank.query.get(blood_bank_id)
        if not blood_bank:
            return jsonify({'success': False, 'message': 'Blood bank not found'}), 404
        
        return jsonify({'success': True, 'data': blood_bank.to_dict()})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@blood_bank_bp.route('/blood-type/<string:blood_type>', methods=['GET'])
def find_by_blood_type(blood_type):
    """Find blood banks with specific blood type"""
    try:
        min_units = int(request.args.get('minUnits', 1))
        limit = int(request.args.get('limit', 20))
        
        # Map blood type to column name
        column_map = {
            'A+': 'inventory_a_positive',
            'A-': 'inventory_a_negative',
            'B+': 'inventory_b_positive',
            'B-': 'inventory_b_negative',
            'AB+': 'inventory_ab_positive',
            'AB-': 'inventory_ab_negative',
            'O+': 'inventory_o_positive',
            'O-': 'inventory_o_negative'
        }
        
        column_name = column_map.get(blood_type)
        if not column_name:
            return jsonify({'success': False, 'message': 'Invalid blood type'}), 400
        
        blood_banks = BloodBank.query.filter(
            getattr(BloodBank, column_name) >= min_units
        ).limit(limit).all()
        
        return jsonify({
            'success': True,
            'count': len(blood_banks),
            'data': [bb.to_dict() for bb in blood_banks]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@blood_bank_bp.route('/nearby', methods=['POST'])
def find_nearby_blood_banks():
    """Find blood banks near a location"""
    try:
        data = request.json
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        max_distance = data.get('maxDistance', 50)
        blood_type = data.get('bloodType')
        min_units = data.get('minUnits', 1)
        limit = data.get('limit', 20)
        
        if not latitude or not longitude:
            return jsonify({'success': False, 'message': 'Latitude and longitude required'}), 400
        
        query = BloodBank.query
        
        # Filter by blood type if specified
        if blood_type:
            column_map = {
                'A+': 'inventory_a_positive',
                'A-': 'inventory_a_negative',
                'B+': 'inventory_b_positive',
                'B-': 'inventory_b_negative',
                'AB+': 'inventory_ab_positive',
                'AB-': 'inventory_ab_negative',
                'O+': 'inventory_o_positive',
                'O-': 'inventory_o_negative'
            }
            column_name = column_map.get(blood_type)
            if column_name:
                query = query.filter(getattr(BloodBank, column_name) >= min_units)
        
        blood_banks = query.all()
        
        # Calculate distances
        nearby_banks = []
        for bank in blood_banks:
            try:
                distance = maps_service.calculate_distance(
                    (latitude, longitude),
                    (float(bank.latitude), float(bank.longitude))
                )
                if distance <= max_distance:
                    bank_dict = bank.to_dict()
                    bank_dict['distance'] = distance
                    if blood_type:
                        bank_dict['availableUnits'] = bank.get_inventory().get(blood_type, 0)
                    nearby_banks.append(bank_dict)
            except:
                continue
        
        # Sort by distance
        nearby_banks.sort(key=lambda x: x['distance'])
        
        return jsonify({
            'success': True,
            'count': len(nearby_banks[:limit]),
            'data': nearby_banks[:limit]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@blood_bank_bp.route('/<int:blood_bank_id>/inventory', methods=['PUT'])
def update_inventory(blood_bank_id):
    """Update blood bank inventory"""
    try:
        blood_bank = BloodBank.query.get(blood_bank_id)
        if not blood_bank:
            return jsonify({'success': False, 'message': 'Blood bank not found'}), 404
        
        data = request.json.get('bloodInventory', {})
        
        blood_bank.inventory_a_positive = data.get('A+', blood_bank.inventory_a_positive)
        blood_bank.inventory_a_negative = data.get('A-', blood_bank.inventory_a_negative)
        blood_bank.inventory_b_positive = data.get('B+', blood_bank.inventory_b_positive)
        blood_bank.inventory_b_negative = data.get('B-', blood_bank.inventory_b_negative)
        blood_bank.inventory_ab_positive = data.get('AB+', blood_bank.inventory_ab_positive)
        blood_bank.inventory_ab_negative = data.get('AB-', blood_bank.inventory_ab_negative)
        blood_bank.inventory_o_positive = data.get('O+', blood_bank.inventory_o_positive)
        blood_bank.inventory_o_negative = data.get('O-', blood_bank.inventory_o_negative)
        
        from datetime import datetime
        blood_bank.last_inventory_update = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Inventory updated successfully',
            'data': blood_bank.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@blood_bank_bp.route('/stats/inventory', methods=['GET'])
def get_inventory_stats():
    """Get total inventory across all blood banks"""
    try:
        result = db.session.query(
            db.func.sum(BloodBank.inventory_a_positive).label('A+'),
            db.func.sum(BloodBank.inventory_a_negative).label('A-'),
            db.func.sum(BloodBank.inventory_b_positive).label('B+'),
            db.func.sum(BloodBank.inventory_b_negative).label('B-'),
            db.func.sum(BloodBank.inventory_ab_positive).label('AB+'),
            db.func.sum(BloodBank.inventory_ab_negative).label('AB-'),
            db.func.sum(BloodBank.inventory_o_positive).label('O+'),
            db.func.sum(BloodBank.inventory_o_negative).label('O-')
        ).first()
        
        return jsonify({
            'success': True,
            'data': {
                'A+': result[0] or 0,
                'A-': result[1] or 0,
                'B+': result[2] or 0,
                'B-': result[3] or 0,
                'AB+': result[4] or 0,
                'AB-': result[5] or 0,
                'O+': result[6] or 0,
                'O-': result[7] or 0
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
