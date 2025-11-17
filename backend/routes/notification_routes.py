from flask import Blueprint, request, jsonify
from extensions import db
from models.blood_request import Notification
from datetime import datetime

notification_bp = Blueprint('notifications', __name__)

@notification_bp.route('/', methods=['GET'])
def get_notifications():
    """Get notifications for a recipient"""
    try:
        recipient_id = request.args.get('recipientId')
        recipient_type = request.args.get('recipientType')
        unread_only = request.args.get('unreadOnly', 'false').lower() == 'true'
        limit = int(request.args.get('limit', 50))
        
        if not recipient_id:
            return jsonify({
                'success': False,
                'message': 'recipientId is required'
            }), 400
        
        query = Notification.query.filter_by(recipient_id=int(recipient_id))
        
        if recipient_type:
            query = query.filter_by(recipient_type=recipient_type)
        if unread_only:
            query = query.filter_by(read=False)
        
        notifications = query.order_by(Notification.created_at.desc()).limit(limit).all()
        
        unread_count = Notification.query.filter_by(
            recipient_id=int(recipient_id),
            read=False
        ).count()
        
        return jsonify({
            'success': True,
            'count': len(notifications),
            'unreadCount': unread_count,
            'data': [notif.to_dict() for notif in notifications]
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@notification_bp.route('/<int:notification_id>', methods=['GET'])
def get_notification(notification_id):
    """Get notification by ID"""
    try:
        notification = Notification.query.get(notification_id)
        if not notification:
            return jsonify({'success': False, 'message': 'Notification not found'}), 404
        
        return jsonify({'success': True, 'data': notification.to_dict()})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@notification_bp.route('/', methods=['POST'])
def create_notification():
    """Create new notification"""
    try:
        data = request.json
        
        notification = Notification(
            recipient_id=data.get('recipientId'),
            recipient_type=data.get('recipientType'),
            title=data.get('title'),
            message=data.get('message'),
            notification_type=data.get('type'),
            priority=data.get('priority', 'Medium'),
            data=data.get('data')
        )
        
        db.session.add(notification)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Notification created successfully',
            'data': notification.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@notification_bp.route('/<int:notification_id>/read', methods=['PUT'])
def mark_as_read(notification_id):
    """Mark notification as read"""
    try:
        notification = Notification.query.get(notification_id)
        if not notification:
            return jsonify({'success': False, 'message': 'Notification not found'}), 404
        
        notification.read = True
        notification.read_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Notification marked as read',
            'data': notification.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@notification_bp.route('/read-all/<int:recipient_id>', methods=['PUT'])
def mark_all_as_read(recipient_id):
    """Mark all notifications as read for a recipient"""
    try:
        result = Notification.query.filter_by(
            recipient_id=recipient_id,
            read=False
        ).update({
            'read': True,
            'read_at': datetime.utcnow()
        })
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Marked {result} notifications as read',
            'modifiedCount': result
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


@notification_bp.route('/<int:notification_id>', methods=['DELETE'])
def delete_notification(notification_id):
    """Delete notification"""
    try:
        notification = Notification.query.get(notification_id)
        if not notification:
            return jsonify({'success': False, 'message': 'Notification not found'}), 404
        
        db.session.delete(notification)
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Notification deleted successfully'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@notification_bp.route('/count/unread/<int:recipient_id>', methods=['GET'])
def get_unread_count(recipient_id):
    """Get unread notification count"""
    try:
        count = Notification.query.filter_by(
            recipient_id=recipient_id,
            read=False
        ).count()
        
        return jsonify({
            'success': True,
            'unreadCount': count
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
