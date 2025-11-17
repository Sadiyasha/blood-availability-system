from flask import Blueprint, request, jsonify
from extensions import db
from models.donor import Donor
from services.google_maps_service import maps_service
from sqlalchemy import or_

donor_bp = Blueprint('donors', __name__)

@donor_bp.route('/', methods=['GET'])
def get_donors():
    """Get all donors with optional filters"""
    try:
        blood_type = request.args.get('bloodType')
        city = request.args.get('city')
        available = request.args.get('available')
        limit = int(request.args.get('limit', 50))
        
        query = Donor.query
        
        if blood_type:
            query = query.filter(Donor.blood_type == blood_type)
        if city:
            query = query.filter(Donor.city.ilike(f'%{city}%'))
        if available:
            query = query.filter(Donor.available_for_donation == (available.lower() == 'true'))
        
        donors = query.limit(limit).all()
        
        return jsonify({
            'success': True,
            'count': len(donors),
            'data': [donor.to_dict() for donor in donors]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@donor_bp.route('/<int:donor_id>', methods=['GET'])
def get_donor(donor_id):
    """Get donor by ID"""
    try:
        donor = Donor.query.get(donor_id)
        if not donor:
            return jsonify({'success': False, 'message': 'Donor not found'}), 404
        
        return jsonify({'success': True, 'data': donor.to_dict()})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@donor_bp.route('/nearby', methods=['POST'])
def find_nearby_donors():
    """Find donors near a location"""
    try:
        data = request.json
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        max_distance = data.get('maxDistance', 50)  # km
        blood_type = data.get('bloodType')
        limit = data.get('limit', 20)
        
        if not latitude or not longitude:
            return jsonify({'success': False, 'message': 'Latitude and longitude required'}), 400
        
        # Get all donors (with optional blood type filter)
        query = Donor.query.filter(Donor.available_for_donation == True)
        if blood_type:
            query = query.filter(Donor.blood_type == blood_type)
        
        donors = query.all()
        
        # Calculate distances
        nearby_donors = []
        for donor in donors:
            try:
                distance = maps_service.calculate_distance(
                    (latitude, longitude),
                    (float(donor.latitude), float(donor.longitude))
                )
                if distance <= max_distance:
                    donor_dict = donor.to_dict()
                    donor_dict['distance'] = distance
                    nearby_donors.append(donor_dict)
            except:
                continue
        
        # Sort by distance
        nearby_donors.sort(key=lambda x: x['distance'])
        
        return jsonify({
            'success': True,
            'count': len(nearby_donors[:limit]),
            'data': nearby_donors[:limit]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@donor_bp.route('/search', methods=['POST'])
def search_donors():
    """Search donors with flexible filter keys (supports blood_group/bloodType, city, state, is_available)"""
    try:
        data = request.get_json(silent=True) or {}

        # Accept multiple possible keys from frontend
        blood_type = data.get('blood_group') or data.get('bloodType') or data.get('blood')
        city = data.get('city') or (data.get('address') or {}).get('city') or data.get('location')
        state = data.get('state') or (data.get('address') or {}).get('state')
        available = data.get('is_available') if 'is_available' in data else data.get('available') if 'available' in data else data.get('availableForDonation')
        limit = int(data.get('limit', 50))

        query = Donor.query
        if blood_type:
            query = query.filter(Donor.blood_type == blood_type)
        if city:
            query = query.filter(Donor.city.ilike(f'%{city}%'))
        if state:
            query = query.filter(Donor.state.ilike(f'%{state}%'))
        if available is not None:
            # Normalize boolean-like values
            if isinstance(available, str):
                available_bool = available.lower() in ('1', 'true', 'yes')
            else:
                available_bool = bool(available)
            query = query.filter(Donor.available_for_donation == available_bool)

        donors = query.limit(limit).all()

        return jsonify({
            'success': True,
            'count': len(donors),
            'data': [donor.to_dict() for donor in donors]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@donor_bp.route('/', methods=['POST'])
def create_donor():
    """Create new donor"""
    try:
        data = request.json
        
        # Check if phone already exists
        existing = Donor.query.filter_by(phone=data.get('phone')).first()
        if existing:
            return jsonify({'success': False, 'message': 'Phone number already registered'}), 400
        
        donor = Donor(
            name=data.get('name'),
            blood_type=data.get('bloodType'),
            phone=data.get('phone'),
            email=data.get('email'),
            age=data.get('age'),
            gender=data.get('gender'),
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            street=data.get('address', {}).get('street'),
            city=data.get('address', {}).get('city'),
            state=data.get('address', {}).get('state'),
            pincode=data.get('address', {}).get('pincode'),
            available_for_donation=data.get('availableForDonation', True)
        )
        
        db.session.add(donor)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Donor created successfully',
            'data': donor.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@donor_bp.route('/<int:donor_id>', methods=['PUT'])
def update_donor(donor_id):
    """Update donor"""
    try:
        donor = Donor.query.get(donor_id)
        if not donor:
            return jsonify({'success': False, 'message': 'Donor not found'}), 404
        
        data = request.json
        
        # Update fields
        if 'name' in data:
            donor.name = data['name']
        if 'bloodType' in data:
            donor.blood_type = data['bloodType']
        if 'email' in data:
            donor.email = data['email']
        if 'availableForDonation' in data:
            donor.available_for_donation = data['availableForDonation']
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Donor updated successfully',
            'data': donor.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@donor_bp.route('/<int:donor_id>', methods=['DELETE'])
def delete_donor(donor_id):
    """Delete donor"""
    try:
        donor = Donor.query.get(donor_id)
        if not donor:
            return jsonify({'success': False, 'message': 'Donor not found'}), 404
        
        db.session.delete(donor)
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Donor deleted successfully'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@donor_bp.route('/stats/summary', methods=['GET'])
def get_donor_stats():
    """Get donor statistics"""
    try:
        stats = db.session.query(
            Donor.blood_type,
            db.func.count(Donor.id).label('total'),
            db.func.sum(db.case((Donor.available_for_donation == True, 1), else_=0)).label('available')
        ).group_by(Donor.blood_type).all()
        
        result = []
        for stat in stats:
            result.append({
                'bloodType': stat.blood_type,
                'total': stat.total,
                'available': stat.available
            })
        
        return jsonify({'success': True, 'data': result})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
