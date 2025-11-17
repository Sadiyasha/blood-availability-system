from flask import Blueprint, request, jsonify
from extensions import db
from models.blood_request import BloodRequest
from datetime import datetime

blood_request_bp = Blueprint('blood_requests', __name__)

@blood_request_bp.route('/', methods=['GET'])
def get_blood_requests():
    """Get all blood requests with filters"""
    try:
        status = request.args.get('status')
        urgency = request.args.get('urgency')
        blood_type = request.args.get('bloodType')
        limit = int(request.args.get('limit', 50))
        
        query = BloodRequest.query
        
        if status:
            query = query.filter(BloodRequest.status == status)
        if urgency:
            query = query.filter(BloodRequest.urgency == urgency)
        if blood_type:
            query = query.filter(BloodRequest.blood_type == blood_type)
        
        requests = query.order_by(BloodRequest.created_at.desc()).limit(limit).all()
        
        return jsonify({
            'success': True,
            'count': len(requests),
            'data': [req.to_dict() for req in requests]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@blood_request_bp.route('/<int:request_id>', methods=['GET'])
def get_blood_request(request_id):
    """Get blood request by ID"""
    try:
        blood_request = BloodRequest.query.get(request_id)
        if not blood_request:
            return jsonify({'success': False, 'message': 'Blood request not found'}), 404
        
        return jsonify({'success': True, 'data': blood_request.to_dict()})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@blood_request_bp.route('/', methods=['POST'])
def create_blood_request():
    """Create new blood request"""
    try:
        data = request.json
        
        blood_request = BloodRequest(
            patient_name=data.get('patientName'),
            blood_type=data.get('bloodType'),
            units_required=data.get('unitsRequired'),
            urgency=data.get('urgency', 'Normal'),
            hospital_id=data.get('hospitalId'),
            requester_name=data.get('requesterContact', {}).get('name'),
            requester_phone=data.get('requesterContact', {}).get('phone'),
            requester_email=data.get('requesterContact', {}).get('email'),
            requester_relation=data.get('requesterContact', {}).get('relation'),
            latitude=data.get('location', {}).get('latitude'),
            longitude=data.get('location', {}).get('longitude'),
            reason=data.get('reason'),
            required_by=datetime.fromisoformat(data.get('requiredBy').replace('Z', '+00:00')),
            notes=data.get('notes')
        )
        
        db.session.add(blood_request)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Blood request created successfully',
            'data': blood_request.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@blood_request_bp.route('/<int:request_id>/status', methods=['PUT'])
def update_status(request_id):
    """Update blood request status"""
    try:
        blood_request = BloodRequest.query.get(request_id)
        if not blood_request:
            return jsonify({'success': False, 'message': 'Blood request not found'}), 404
        
        data = request.json
        new_status = data.get('status')
        
        blood_request.status = new_status
        if new_status == 'Fulfilled':
            blood_request.fulfilled_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Blood request status updated to {new_status}',
            'data': blood_request.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@blood_request_bp.route('/<int:request_id>', methods=['PUT'])
def update_blood_request(request_id):
    """Update blood request"""
    try:
        blood_request = BloodRequest.query.get(request_id)
        if not blood_request:
            return jsonify({'success': False, 'message': 'Blood request not found'}), 404
        
        data = request.json
        
        if 'status' in data:
            blood_request.status = data['status']
        if 'notes' in data:
            blood_request.notes = data['notes']
        if 'urgency' in data:
            blood_request.urgency = data['urgency']
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Blood request updated successfully',
            'data': blood_request.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@blood_request_bp.route('/<int:request_id>', methods=['DELETE'])
def delete_blood_request(request_id):
    """Delete blood request"""
    try:
        blood_request = BloodRequest.query.get(request_id)
        if not blood_request:
            return jsonify({'success': False, 'message': 'Blood request not found'}), 404
        
        db.session.delete(blood_request)
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Blood request deleted successfully'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@blood_request_bp.route('/urgent', methods=['GET'])
def get_urgent_requests():
    """Get urgent and critical blood requests"""
    try:
        requests = BloodRequest.query.filter(
            BloodRequest.status.in_(['Pending', 'Matched']),
            BloodRequest.urgency.in_(['Critical', 'Urgent']),
            BloodRequest.required_by >= datetime.utcnow()
        ).order_by(
            BloodRequest.urgency.desc(),
            BloodRequest.required_by.asc()
        ).limit(20).all()
        
        return jsonify({
            'success': True,
            'count': len(requests),
            'data': [req.to_dict() for req in requests]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
