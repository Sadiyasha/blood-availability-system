from flask import Blueprint, request, jsonify
from extensions import db
from models.donor import Donor
from models.hospital import Hospital
from models.blood_bank import BloodBank
import services.google_maps_service as gmaps

map_bp = Blueprint('map', __name__)


def _calc_distance(origin, destination):
    """Safely calculate distance using the live maps service if available.

    Avoid importing the maps_service object directly at import time because
    it is initialized later in the app factory. Instead, reference the
    module attribute dynamically or fall back to a fresh service instance.
    """
    try:
        svc = getattr(gmaps, 'maps_service', None)
        if svc is None:
            svc = gmaps.GoogleMapsService()
        return svc.calculate_distance(origin, destination)
    except Exception:
        return 0

@map_bp.route('/markers', methods=['POST'])
def get_markers():
    """Get all map markers (donors, hospitals, blood banks)"""
    try:
        data = request.json
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        max_distance = data.get('maxDistance', 50)  # km
        include_types = data.get('includeTypes', ['donors', 'hospitals', 'bloodBanks'])
        blood_type = data.get('bloodType')
        limit = data.get('limit', 100)
        
        if not latitude or not longitude:
            return jsonify({
                'success': False,
                'message': 'Latitude and longitude required'
            }), 400
        
        results = {
            'donors': [],
            'hospitals': [],
            'bloodBanks': []
        }
        
        # Get donors
        if 'donors' in include_types:
            query = Donor.query.filter(Donor.available_for_donation == True)
            if blood_type:
                query = query.filter(Donor.blood_type == blood_type)
            
            donors = query.limit(limit).all()
            
            for donor in donors:
                try:
                    distance = _calc_distance(
                        (latitude, longitude),
                        (float(donor.latitude), float(donor.longitude))
                    )
                    if distance <= max_distance:
                        results['donors'].append({
                            'id': donor.id,
                            'type': 'donor',
                            'name': donor.name,
                            'bloodType': donor.blood_type,
                            'coordinates': {
                                'latitude': float(donor.latitude),
                                'longitude': float(donor.longitude)
                            },
                            'phone': donor.phone,
                            'rating': float(donor.rating) if donor.rating else 5.0,
                            'distance': distance
                        })
                except:
                    continue
        
        # Get hospitals
        if 'hospitals' in include_types:
            hospitals = Hospital.query.limit(limit).all()
            
            for hospital in hospitals:
                try:
                    distance = _calc_distance(
                        (latitude, longitude),
                        (float(hospital.latitude), float(hospital.longitude))
                    )
                    if distance <= max_distance:
                        results['hospitals'].append({
                            'id': hospital.id,
                            'type': 'hospital',
                            'name': hospital.name,
                            'hospitalType': hospital.hospital_type,
                            'coordinates': {
                                'latitude': float(hospital.latitude),
                                'longitude': float(hospital.longitude)
                            },
                            'phone': hospital.phone,
                            'emergencyContact': hospital.emergency_contact,
                            'hasBloodBank': hospital.has_blood_bank,
                            'distance': distance
                        })
                except:
                    continue
        
        # Get blood banks
        if 'bloodBanks' in include_types:
            blood_banks = BloodBank.query.limit(limit).all()
            
            for bank in blood_banks:
                try:
                    distance = _calc_distance(
                        (latitude, longitude),
                        (float(bank.latitude), float(bank.longitude))
                    )
                    if distance <= max_distance:
                        results['bloodBanks'].append({
                            'id': bank.id,
                            'type': 'bloodBank',
                            'name': bank.name,
                            'coordinates': {
                                'latitude': float(bank.latitude),
                                'longitude': float(bank.longitude)
                            },
                            'phone': bank.phone,
                            'inventory': bank.get_inventory(),
                            'distance': distance
                        })
                except:
                    continue
        
        total_markers = len(results['donors']) + len(results['hospitals']) + len(results['bloodBanks'])
        
        return jsonify({
            'success': True,
            'center': {'latitude': latitude, 'longitude': longitude},
            'radiusKm': max_distance,
            'summary': {
                'totalMarkers': total_markers,
                'donors': len(results['donors']),
                'hospitals': len(results['hospitals']),
                'bloodBanks': len(results['bloodBanks'])
            },
            'data': results
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@map_bp.route('/city-counts', methods=['POST'])
def get_city_counts():
    """Return marker counts for a set of city centers.

    Request JSON (optional fields):
      - cities: [ { name, latitude, longitude } ]
      - maxDistance: km radius (default 120)
      - includeTypes: ['bloodBanks'|'hospitals'|'donors'] (default ['bloodBanks'])

    If 'cities' not provided, uses a default list of major Indian cities.
    """
    try:
        data = request.json or {}
        max_distance = data.get('maxDistance', 120)
        include_types = data.get('includeTypes', ['bloodBanks'])

        default_cities = [
            {'name': 'Bangalore', 'latitude': 12.9716, 'longitude': 77.5946},
            {'name': 'Mumbai', 'latitude': 19.0760, 'longitude': 72.8777},
            {'name': 'Delhi', 'latitude': 28.7041, 'longitude': 77.1025},
            {'name': 'Hyderabad', 'latitude': 17.3850, 'longitude': 78.4867},
            {'name': 'Chennai', 'latitude': 13.0827, 'longitude': 80.2707},
            {'name': 'Kolkata', 'latitude': 22.5726, 'longitude': 88.3639},
            {'name': 'Pune', 'latitude': 18.5204, 'longitude': 73.8567},
            {'name': 'Ahmedabad', 'latitude': 23.0225, 'longitude': 72.5714},
        ]

        cities = data.get('cities') or default_cities

        # Prefetch datasets to avoid repeated DB trips per city
        donors_all = Donor.query.filter(Donor.available_for_donation == True).all() if 'donors' in include_types else []
        hospitals_all = Hospital.query.all() if 'hospitals' in include_types else []
        banks_all = BloodBank.query.all() if 'bloodBanks' in include_types else []

        results = []
        totals = {'donors': 0, 'hospitals': 0, 'bloodBanks': 0}

        for c in cities:
            name = c.get('name', 'Unknown')
            lat = float(c.get('latitude'))
            lon = float(c.get('longitude'))
            center = (lat, lon)

            counts = {'donors': 0, 'hospitals': 0, 'bloodBanks': 0}

            if donors_all:
                for d in donors_all:
                    try:
                        dist = _calc_distance(center, (float(d.latitude), float(d.longitude)))
                        if dist <= max_distance:
                            counts['donors'] += 1
                    except Exception:
                        continue

            if hospitals_all:
                for h in hospitals_all:
                    try:
                        dist = _calc_distance(center, (float(h.latitude), float(h.longitude)))
                        if dist <= max_distance:
                            counts['hospitals'] += 1
                    except Exception:
                        continue

            if banks_all:
                for b in banks_all:
                    try:
                        dist = _calc_distance(center, (float(b.latitude), float(b.longitude)))
                        if dist <= max_distance:
                            counts['bloodBanks'] += 1
                    except Exception:
                        continue

            totals['donors'] += counts['donors']
            totals['hospitals'] += counts['hospitals']
            totals['bloodBanks'] += counts['bloodBanks']

            results.append({
                'name': name,
                'center': {'latitude': lat, 'longitude': lon},
                'radiusKm': max_distance,
                'counts': counts
            })

        return jsonify({
            'success': True,
            'radiusKm': max_distance,
            'includeTypes': include_types,
            'summary': totals,
            'cities': results
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@map_bp.route('/heatmap', methods=['POST'])
def get_heatmap():
    """Get heatmap data for blood availability"""
    try:
        data = request.json
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        max_distance = data.get('maxDistance', 100)  # km
        blood_type = data.get('bloodType')
        
        if not latitude or not longitude or not blood_type:
            return jsonify({
                'success': False,
                'message': 'Latitude, longitude, and blood type are required'
            }), 400
        
        heatmap_data = []
        
        # Add donors
        donors = Donor.query.filter(
            Donor.blood_type == blood_type,
            Donor.available_for_donation == True
        ).all()
        
        for donor in donors:
            try:
                distance = maps_service.calculate_distance(
                    (latitude, longitude),
                    (float(donor.latitude), float(donor.longitude))
                )
                if distance <= max_distance:
                    heatmap_data.append({
                        'latitude': float(donor.latitude),
                        'longitude': float(donor.longitude),
                        'weight': 1.0
                    })
            except:
                continue
        
        # Add blood banks with weighted intensity
        column_map = {
            'A+': 'inventory_a_positive', 'A-': 'inventory_a_negative',
            'B+': 'inventory_b_positive', 'B-': 'inventory_b_negative',
            'AB+': 'inventory_ab_positive', 'AB-': 'inventory_ab_negative',
            'O+': 'inventory_o_positive', 'O-': 'inventory_o_negative'
        }
        
        column_name = column_map.get(blood_type)
        if column_name:
            blood_banks = BloodBank.query.filter(
                getattr(BloodBank, column_name) >= 1
            ).all()
            
            for bank in blood_banks:
                try:
                    distance = maps_service.calculate_distance(
                        (latitude, longitude),
                        (float(bank.latitude), float(bank.longitude))
                    )
                    if distance <= max_distance:
                        inventory = getattr(bank, column_name)
                        weight = min(inventory / 10.0, 5.0)  # Scale weight
                        heatmap_data.append({
                            'latitude': float(bank.latitude),
                            'longitude': float(bank.longitude),
                            'weight': weight
                        })
                except:
                    continue
        
        return jsonify({
            'success': True,
            'bloodType': blood_type,
            'center': {'latitude': latitude, 'longitude': longitude},
            'radiusKm': max_distance,
            'pointsCount': len(heatmap_data),
            'data': heatmap_data
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@map_bp.route('/directions', methods=['POST'])
def get_directions():
    """Get route/directions between origin and destination and return polyline points"""
    try:
        data = request.json or {}
        origin = data.get('origin')  # {'latitude': x, 'longitude': y}
        destination = data.get('destination')

        if not origin or not destination:
            return jsonify({'success': False, 'message': 'origin and destination required'}), 400

        origin_tuple = (origin.get('latitude'), origin.get('longitude'))
        dest_tuple = (destination.get('latitude'), destination.get('longitude'))

        # Use maps_service to get directions (may include polyline)
        directions = maps_service.get_directions(origin_tuple, dest_tuple)

        # Ensure a route structure: list of {latitude, longitude}
        route = directions.get('polyline') if isinstance(directions, dict) else None
        if not route:
            # Fallback: simple two-point line
            route = [
                {'latitude': float(origin_tuple[0]), 'longitude': float(origin_tuple[1])},
                {'latitude': float(dest_tuple[0]), 'longitude': float(dest_tuple[1])}
            ]

        return jsonify({
            'success': True,
            'distance': directions.get('distance') if isinstance(directions, dict) else None,
            'duration': directions.get('duration') if isinstance(directions, dict) else None,
            'route': route
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
