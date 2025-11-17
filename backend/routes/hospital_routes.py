from flask import Blueprint, request, jsonify
from extensions import db
from models.hospital import Hospital
from services.google_maps_service import maps_service

hospital_bp = Blueprint('hospitals', __name__)

@hospital_bp.route('/', methods=['GET'])
def get_hospitals():
    """Get all hospitals with optional filters"""
    try:
        city = request.args.get('city')
        state = request.args.get('state')
        hospital_type = request.args.get('type')
        has_blood_bank = request.args.get('hasBloodBank')
        limit = int(request.args.get('limit', 50))
        
        query = Hospital.query
        
        if city:
            query = query.filter(Hospital.city.ilike(f'%{city}%'))
        if state:
            query = query.filter(Hospital.state.ilike(f'%{state}%'))
        if hospital_type:
            query = query.filter(Hospital.hospital_type == hospital_type)
        if has_blood_bank:
            query = query.filter(Hospital.has_blood_bank == (has_blood_bank.lower() == 'true'))
        
        hospitals = query.limit(limit).all()
        
        return jsonify({
            'success': True,
            'count': len(hospitals),
            'data': [hospital.to_dict() for hospital in hospitals]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@hospital_bp.route('/<int:hospital_id>', methods=['GET'])
def get_hospital(hospital_id):
    """Get hospital by ID"""
    try:
        hospital = Hospital.query.get(hospital_id)
        if not hospital:
            return jsonify({'success': False, 'message': 'Hospital not found'}), 404
        
        return jsonify({'success': True, 'data': hospital.to_dict()})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@hospital_bp.route('/nearby', methods=['POST'])
def find_nearby_hospitals():
    """Find hospitals near a location"""
    try:
        data = request.json
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        max_distance = data.get('maxDistance', 50)  # km
        limit = data.get('limit', 20)
        
        if not latitude or not longitude:
            return jsonify({'success': False, 'message': 'Latitude and longitude required'}), 400
        
        hospitals = Hospital.query.all()
        
        # Calculate distances
        nearby_hospitals = []
        for hospital in hospitals:
            try:
                distance = maps_service.calculate_distance(
                    (latitude, longitude),
                    (float(hospital.latitude), float(hospital.longitude))
                )
                if distance <= max_distance:
                    hospital_dict = hospital.to_dict()
                    hospital_dict['distance'] = distance
                    nearby_hospitals.append(hospital_dict)
            except:
                continue
        
        # Sort by distance
        nearby_hospitals.sort(key=lambda x: x['distance'])
        
        return jsonify({
            'success': True,
            'count': len(nearby_hospitals[:limit]),
            'data': nearby_hospitals[:limit]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@hospital_bp.route('/', methods=['POST'])
def create_hospital():
    """Create new hospital"""
    try:
        data = request.json
        
        hospital = Hospital(
            name=data.get('name'),
            hospital_type=data.get('hospitalType', 'Government'),
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            street=data.get('address', {}).get('street'),
            city=data.get('address', {}).get('city'),
            state=data.get('address', {}).get('state'),
            pincode=data.get('address', {}).get('pincode'),
            phone=data.get('phone'),
            email=data.get('email'),
            emergency_contact=data.get('emergencyContact'),
            has_blood_bank=data.get('hasBloodBank', False)
        )
        
        db.session.add(hospital)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Hospital created successfully',
            'data': hospital.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@hospital_bp.route('/<int:hospital_id>', methods=['PUT'])
def update_hospital(hospital_id):
    """Update hospital"""
    try:
        hospital = Hospital.query.get(hospital_id)
        if not hospital:
            return jsonify({'success': False, 'message': 'Hospital not found'}), 404
        
        data = request.json
        
        if 'name' in data:
            hospital.name = data['name']
        if 'phone' in data:
            hospital.phone = data['phone']
        if 'hasBloodBank' in data:
            hospital.has_blood_bank = data['hasBloodBank']
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Hospital updated successfully',
            'data': hospital.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@hospital_bp.route('/<int:hospital_id>', methods=['DELETE'])
def delete_hospital(hospital_id):
    """Delete hospital"""
    try:
        hospital = Hospital.query.get(hospital_id)
        if not hospital:
            return jsonify({'success': False, 'message': 'Hospital not found'}), 404
        
        db.session.delete(hospital)
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Hospital deleted successfully'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
