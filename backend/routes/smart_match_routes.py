from flask import Blueprint, request, jsonify
from extensions import db
from models.donor import Donor
from models.blood_bank import BloodBank
from services.ai_matching_service import matching_engine, BLOOD_COMPATIBILITY

smart_match_bp = Blueprint('smart_match', __name__)

@smart_match_bp.route('/find-donors', methods=['POST'])
def find_donors():
    """AI-powered donor matching using IBDMA algorithm"""
    try:
        data = request.json
        blood_type = data.get('bloodType')
        location = data.get('location')  # {latitude, longitude} or {lat, lng}
        urgency = data.get('urgency', 'Normal')
        max_distance = data.get('maxDistance', 50)
        limit = data.get('limit', 20)
        
        if not blood_type or not location:
            return jsonify({
                'success': False,
                'message': 'Blood type and location are required'
            }), 400
        
        # Get compatible blood types
        compatible_types = BLOOD_COMPATIBILITY.get(blood_type, [blood_type])

        # Normalize location to expected keys
        if 'lat' in location and 'lng' in location:
            request_location = {
                'latitude': float(location['lat']),
                'longitude': float(location['lng'])
            }
        else:
            request_location = {
                'latitude': float(location['latitude']),
                'longitude': float(location['longitude'])
            }
        
        # Query donors
        donors = Donor.query.filter(
            Donor.blood_type.in_(compatible_types),
            Donor.available_for_donation == True
        ).all()
        
        # Convert to dict for matching engine
        donor_dicts = [donor.to_dict() for donor in donors]
        
        # Use AI matching engine
        matches = matching_engine.find_best_matches(
            donor_dicts,
            request_location,
            urgency,
            blood_type,
            limit
        )
        # Filter by max distance if provided
        try:
            matches = [m for m in matches if float(m.get('distance', 9999)) <= float(max_distance)]
        except Exception:
            pass

        # Transform to frontend-friendly schema
        transformed = []
        for m in matches:
            d = m.get('donor', {})
            transformed.append({
                'user': {
                    'name': d.get('name'),
                    'phone': d.get('phone'),
                    'city': (d.get('address') or {}).get('city'),
                    'state': (d.get('address') or {}).get('state'),
                },
                'blood_group': d.get('bloodType'),
                'distance': m.get('distance'),
                'score': m.get('matchScore'),
                'raw': m,
            })
        
        # Get statistics
        stats = matching_engine.get_statistics(matches)
        
        return jsonify({
            'success': True,
            'count': len(transformed),
            'searchCriteria': {
                'bloodType': blood_type,
                'location': location,
                'urgency': urgency,
                'maxDistance': max_distance
            },
            'statistics': stats,
            'data': transformed
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@smart_match_bp.route('/find-blood-banks', methods=['POST'])
def find_blood_banks():
    """Find blood banks with required blood type"""
    try:
        data = request.json
        blood_type = data.get('bloodType')
        location = data.get('location')
        min_units = data.get('minUnits', 1)
        max_distance = data.get('maxDistance', 50)
        limit = data.get('limit', 20)
        
        if not blood_type or not location:
            return jsonify({
                'success': False,
                'message': 'Blood type and location are required'
            }), 400
        
        # Normalize location keys if needed
        if 'lat' in location and 'lng' in location:
            norm_location = {
                'latitude': float(location['lat']),
                'longitude': float(location['lng'])
            }
        else:
            norm_location = {
                'latitude': float(location['latitude']),
                'longitude': float(location['longitude'])
            }
        
        # Map blood type to column
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
        ).all()
        
        # Calculate distances and sort
        from services.google_maps_service import maps_service
        results = []
        for bank in blood_banks:
            try:
                distance = maps_service.calculate_distance(
                    (norm_location['latitude'], norm_location['longitude']),
                    (float(bank.latitude), float(bank.longitude))
                )
                if distance <= max_distance:
                    bank_dict = bank.to_dict()
                    bank_dict['distance'] = distance
                    bank_dict['availableUnits'] = getattr(bank, column_name)
                    results.append(bank_dict)
            except:
                continue
        
        results.sort(key=lambda x: x['distance'])
        
        return jsonify({
            'success': True,
            'count': len(results[:limit]),
            'data': results[:limit]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@smart_match_bp.route('/comprehensive-search', methods=['POST'])
def comprehensive_search():
    """Combined search for both donors and blood banks"""
    try:
        data = request.json
        blood_type = data.get('bloodType')
        location = data.get('location')
        urgency = data.get('urgency', 'Normal')
        max_distance = data.get('maxDistance', 50)
        units_required = data.get('unitsRequired', 1)
        
        if not blood_type or not location:
            return jsonify({
                'success': False,
                'message': 'Blood type and location are required'
            }), 400
        
        # Normalize location keys if needed
        if 'lat' in location and 'lng' in location:
            norm_location = {
                'latitude': float(location['lat']),
                'longitude': float(location['lng'])
            }
        else:
            norm_location = {
                'latitude': float(location['latitude']),
                'longitude': float(location['longitude'])
            }
        
        # Find donors
        compatible_types = BLOOD_COMPATIBILITY.get(blood_type, [blood_type])
        donors = Donor.query.filter(
            Donor.blood_type.in_(compatible_types),
            Donor.available_for_donation == True
        ).all()
        
        donor_dicts = [donor.to_dict() for donor in donors]
        donor_matches = matching_engine.find_best_matches(
            donor_dicts, norm_location, urgency, blood_type, 10
        )
        
        # Find blood banks
        column_map = {
            'A+': 'inventory_a_positive', 'A-': 'inventory_a_negative',
            'B+': 'inventory_b_positive', 'B-': 'inventory_b_negative',
            'AB+': 'inventory_ab_positive', 'AB-': 'inventory_ab_negative',
            'O+': 'inventory_o_positive', 'O-': 'inventory_o_negative'
        }
        
        column_name = column_map.get(blood_type)
        blood_banks = BloodBank.query.filter(
            getattr(BloodBank, column_name) >= units_required
        ).all() if column_name else []
        
        from services.google_maps_service import maps_service
        bank_results = []
        for bank in blood_banks:
            try:
                distance = maps_service.calculate_distance(
                    (norm_location['latitude'], norm_location['longitude']),
                    (float(bank.latitude), float(bank.longitude))
                )
                if distance <= max_distance:
                    bank_dict = bank.to_dict()
                    bank_dict['distance'] = distance
                    bank_dict['availableUnits'] = getattr(bank, column_name)
                    bank_results.append(bank_dict)
            except:
                continue
        
        bank_results.sort(key=lambda x: x['distance'])
        
        return jsonify({
            'success': True,
            'summary': {
                'donorsFound': len(donor_matches),
                'bloodBanksFound': len(bank_results),
                'totalOptions': len(donor_matches) + len(bank_results)
            },
            'donors': donor_matches,
            'bloodBanks': bank_results[:10]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
