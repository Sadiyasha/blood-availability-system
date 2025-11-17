"""
Google Maps API Integration Service
Handles geocoding, distance calculations, and location services
"""

from datetime import datetime
from flask import current_app
from geopy.distance import geodesic


class GoogleMapsService:
    """Google Maps API integration"""
    
    def __init__(self):
        self.client = None
        # Do not initialize client at import-time. Call init_app(app) or
        # use init_maps_service(app) from the application factory to
        # initialize the client inside an application context.
    
    def _initialize_client(self):
        """Initialize Google Maps client lazily and defensively.

        We import the heavy `googlemaps` dependency inside this method to
        avoid import-time crashes or KeyboardInterrupt propagation during
        module import on some environments. Any error (including
        KeyboardInterrupt) will gracefully disable the live maps client and
        the service will fall back to local geodesic calculations.
        """
        try:  # Broadly catch BaseException to also handle KeyboardInterrupt
            from importlib import import_module

            api_key = current_app.config.get('GOOGLE_MAPS_API_KEY')
            if api_key and api_key != 'YOUR_GOOGLE_MAPS_API_KEY':
                try:
                    googlemaps = import_module('googlemaps')
                    self.client = googlemaps.Client(key=api_key)
                    print("✅ Google Maps API initialized")
                except BaseException as e:  # includes ImportError & KeyboardInterrupt
                    print(f"⚠️  Google Maps client unavailable, using fallback: {e}")
                    self.client = None
            else:
                print("⚠️  Google Maps API key not configured - using fallback geocoding")
        except BaseException as e:
            # Use a safe message — initialization may fail if called outside
            # an application context. The caller should ensure app context.
            print(f"⚠️  Google Maps initialization failed: {e}")
            self.client = None

    def init_app(self, app):
        """Initialize maps client using the given Flask app's config.

        This method should be called with an application context active,
        or it will create one briefly to read the config.
        """
        try:
            # Ensure we run inside the app context when reading config
            with app.app_context():
                self._initialize_client()
        except Exception as e:
            print(f"⚠️  init_app failed: {e}")
    
    def geocode_address(self, address):
        """
        Convert address to coordinates (latitude, longitude)
        """
        if self.client:
            try:
                geocode_result = self.client.geocode(address)
                if geocode_result:
                    location = geocode_result[0]['geometry']['location']
                    return {
                        'latitude': location['lat'],
                        'longitude': location['lng'],
                        'formatted_address': geocode_result[0]['formatted_address']
                    }
            except Exception as e:
                print(f"Geocoding error: {e}")
        
        # Fallback: return default coordinates (Mumbai, India)
        return {
            'latitude': 19.0760,
            'longitude': 72.8777,
            'formatted_address': address,
            'error': 'Using fallback coordinates'
        }
    
    def reverse_geocode(self, latitude, longitude):
        """
        Convert coordinates to address
        """
        if self.client:
            try:
                reverse_geocode_result = self.client.reverse_geocode((latitude, longitude))
                if reverse_geocode_result:
                    return {
                        'formatted_address': reverse_geocode_result[0]['formatted_address'],
                        'components': reverse_geocode_result[0]['address_components']
                    }
            except Exception as e:
                print(f"Reverse geocoding error: {e}")
        
        return {
            'formatted_address': f"{latitude}, {longitude}",
            'error': 'Reverse geocoding not available'
        }
    
    def calculate_distance(self, origin, destination):
        """
        Calculate distance between two points
        origin and destination: (latitude, longitude) tuples
        Returns distance in kilometers
        """
        try:
            distance = geodesic(origin, destination).kilometers
            return round(distance, 2)
        except Exception as e:
            print(f"Distance calculation error: {e}")
            return 0
    
    def get_directions(self, origin, destination, mode='driving'):
        """
        Get directions between two points
        """
        if self.client:
            try:
                now = datetime.now()
                directions_result = self.client.directions(
                    origin,
                    destination,
                    mode=mode,
                    departure_time=now
                )

                if directions_result:
                    route = directions_result[0]
                    leg = route['legs'][0]

                    # Try to extract overview polyline if present
                    poly_points = []
                    try:
                        encoded = route.get('overview_polyline', {}).get('points')
                        if encoded:
                            poly_points = self._decode_polyline(encoded)
                    except Exception:
                        poly_points = []

                    return {
                        'distance': leg['distance']['text'],
                        'duration': leg['duration']['text'],
                        'start_address': leg['start_address'],
                        'end_address': leg['end_address'],
                        'steps': [step.get('html_instructions') for step in leg.get('steps', [])],
                        'polyline': poly_points
                    }
            except Exception as e:
                print(f"Directions error: {e}")
        
        # Calculate basic distance as fallback
        distance = self.calculate_distance(origin, destination)
        return {
            'distance': f'{distance} km',
            'duration': f'{int(distance * 2)} min',  # Rough estimate
            'start_address': str(origin),
            'end_address': str(destination)
        }

    def _decode_polyline(self, polyline_str):
        """
        Decode an encoded polyline string into a list of (lat, lng) tuples.
        """
        index, lat, lng = 0, 0, 0
        coordinates = []
        length = len(polyline_str)

        while index < length:
            shift, result = 0, 0
            while True:
                b = ord(polyline_str[index]) - 63
                index += 1
                result |= (b & 0x1f) << shift
                shift += 5
                if b < 0x20:
                    break
            dlat = ~(result >> 1) if (result & 1) else (result >> 1)
            lat += dlat

            shift, result = 0, 0
            while True:
                b = ord(polyline_str[index]) - 63
                index += 1
                result |= (b & 0x1f) << shift
                shift += 5
                if b < 0x20:
                    break
            dlng = ~(result >> 1) if (result & 1) else (result >> 1)
            lng += dlng

            coordinates.append((lat / 1e5, lng / 1e5))

        return [{'latitude': lat, 'longitude': lng} for lat, lng in coordinates]
    
    def find_nearest_places(self, location, place_type, radius=5000):
        """
        Find nearest places of a specific type
        place_type: 'hospital', 'pharmacy', etc.
        radius: in meters
        """
        if self.client:
            try:
                places_result = self.client.places_nearby(
                    location=location,
                    radius=radius,
                    type=place_type
                )
                
                return places_result.get('results', [])
            except Exception as e:
                print(f"Places search error: {e}")
        
        return []
    
    def get_city_from_coordinates(self, latitude, longitude):
        """
        Extract city name from coordinates
        """
        result = self.reverse_geocode(latitude, longitude)
        
        if 'components' in result:
            for component in result['components']:
                if 'locality' in component['types']:
                    return component['long_name']
        
        return 'Unknown'


# Singleton instance (initialised explicitly via init_maps_service)
maps_service = None


def init_maps_service(app):
    """Initialize the global maps_service inside an application context.

    Call this from the Flask app factory (create_app) to avoid "working
    outside of application context" errors during import-time initialization.
    """
    global maps_service
    # Create the singleton instance (if not exists) and initialize with app
    if maps_service is None:
        maps_service = GoogleMapsService()
    try:
        maps_service.init_app(app)
    except Exception as e:
        print(f"⚠️  init_maps_service error: {e}")
    return maps_service

