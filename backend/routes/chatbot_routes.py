from flask import Blueprint, request, jsonify
from services.chatbot_service import chatbot
import logging
import os
import json
from flask import current_app
import re

# For live data queries
from services.ai_matching_service import matching_engine, BLOOD_COMPATIBILITY
from models.donor import Donor
from models.blood_bank import BloodBank
from models.hospital import Hospital
from services.google_maps_service import maps_service

chatbot_bp = Blueprint('chatbot', __name__)

# very lightweight in-memory slot storage per user for a conversational flow
_user_sessions = {}
def _get_session(user_id: str):
    """Return a lightweight per-user session dict used for slot filling.

    Fields:
      - bloodType/city/urgency: remembered slots from the conversation
      - awaiting: which slot we asked for last (None | 'city' | 'urgency'),
                  used to decide whether a terse reply should complete the
                  find-donors flow instead of triggering it on every message.
    """
    sess = _user_sessions.get(user_id) or {
        'bloodType': None,
        'city': None,
        'urgency': None,
        'awaiting': None,
    }
    _user_sessions[user_id] = sess
    return sess

@chatbot_bp.route('/query', methods=['POST'])
def handle_query():
    """Handle chatbot query using NLP"""
    try:
        data = request.get_json(silent=True) or {}
        # Log incoming payload for easier debugging
        logging.getLogger('chatbot').info('Incoming chatbot payload: %s', data)
        # Accept both 'message' (frontend older key) and 'query' (api_service uses 'query')
        message = data.get('message') or data.get('query')
        user_id = data.get('userId') or data.get('user_id') or 'guest'

        if not message:
            return jsonify({
                'success': False,
                'message': 'Message is required'
            }), 400

        # Get or create session for this user (used for slot-filling)
        sess = _get_session(user_id)

        # Get chatbot response (defensive)
        try:
            response = chatbot.get_response(message)
        except Exception:
            logging.getLogger('chatbot').exception('Chatbot processing failed for message: %s', message)
            response = {
                'userMessage': message,
                'botResponse': 'Sorry, something went wrong on the server. Please try again later.',
                'intent': 'error',
                'quickActions': [],
                'confidence': 0.0
            }

        # Enhance with live data and slot-filling for certain intents/queries
        intent = response.get('intent', 'default')
        enhanced = None

        try:
            # Get session first before parsing (needed for context-aware city detection)
            sess = _get_session(user_id)
            
            # Try to parse blood type and city from the message
            # Match blood types without relying on word boundaries around '+'
            bt_pattern = re.compile(r"(?<![A-Za-z0-9])(AB\+|AB\-|A\+|A\-|B\+|B\-|O\+|O\-)(?![A-Za-z0-9])", re.IGNORECASE)
            # Capture city after 'in' or 'near', stop before urgency words or end of string
            city_pattern = re.compile(r"\b(?:in|near)\s+([A-Za-z][A-Za-z ]{0,28}?)(?=\s+(?:urgent|critical|now|please|asap)\b|\s*$)", re.IGNORECASE)
            # Urgency words
            urgency_pattern = re.compile(r"\b(critical|urgent|normal)\b", re.IGNORECASE)

            bt_match = bt_pattern.search(message)
            city_match = city_pattern.search(message)
            urgency_match = urgency_pattern.search(message)

            blood_type = bt_match.group(1).upper() if bt_match else None
            city_text = city_match.group(1).strip() if city_match else None

            # If no explicit 'in/near' pattern matched the city, accept a terse standalone city reply
            # BUT exclude common command words like "Blood Banks", "Find Donors", etc.
            excluded_phrases = ['blood bank', 'blood banks', 'find donor', 'find donors', 'check inventory', 
                               'contact', 'register', 'hospitals', 'urgent', 'critical']
            if not city_text:
                cand = message.strip()
                # treat short alphabetic messages (like "Bangalore") as city replies
                # But NOT if it matches excluded command phrases
                # Accept as city only if: 
                # 1) It doesn't match any excluded phrases AND
                # 2) We're explicitly awaiting a city OR we already have a blood type in session
                is_excluded = any(excl in cand.lower() for excl in excluded_phrases)
                print(f"[DEBUG] cand='{cand}', is_excluded={is_excluded}, awaiting={sess.get('awaiting')}, bloodType={sess.get('bloodType')}")
                if re.match(r'^[A-Za-z ]{2,40}$', cand) and not bt_match and not urgency_match and not is_excluded:
                    # Only treat as city if we're in a conversation flow expecting it
                    if sess.get('awaiting') == 'city' or sess.get('bloodType'):
                        city_text = cand
                        print(f"[DEBUG] Set city_text to '{city_text}'")
            urgency = (urgency_match.group(1).capitalize() if urgency_match else
                       ('Urgent' if 'urgent' in message.lower() else 'Normal'))
            # Attach parsed info for transparency
            response['parsed'] = {
                'bloodType': blood_type,
                'city': city_text,
                'urgency': urgency
            }

            # Slot filling: remember known info and ask next question
            if blood_type:
                sess['bloodType'] = blood_type
            if city_text:
                # Don't save invalid "cities" that are actually command phrases
                invalid_cities = ['blood bank', 'blood banks', 'find donor', 'find donors', 'check inventory', 
                                 'contact', 'register', 'hospitals']
                if not any(inv in city_text.lower() for inv in invalid_cities):
                    sess['city'] = city_text
            # only update urgency if explicitly provided in message
            if urgency_match:
                sess['urgency'] = urgency

            # Helper to geocode a city, fallback to Delhi
            def geocode_city(city_str):
                try:
                    loc = maps_service.geocode_address(city_str)
                    if loc and 'latitude' in loc and 'longitude' in loc:
                        return {'latitude': float(loc['latitude']), 'longitude': float(loc['longitude'])}
                except Exception:
                    pass
                # Default to Delhi if geocoding fails or not provided
                return {'latitude': 28.6139, 'longitude': 77.2090}

            # Hints from raw message text
            lowered = message.lower()
            find_donors_hint = any(k in lowered for k in ['find donor', 'need blood', 'search donor', 'require blood', 'smart match', 'donor'])
            blood_bank_hint = any(k in lowered for k in ['blood bank', 'blood banks', 'check blood bank', 'show blood bank', 'find blood bank'])
            inventory_hint = any(k in lowered for k in ['availability', 'stock', 'units', 'inventory'])
            hospital_hint = 'hospital' in lowered
            contact_hint = any(k in lowered for k in ['contact', 'phone', 'call'])

            # If we have partial info, guide the user to provide the next slot
            if enhanced is None:
                if sess['bloodType'] and not sess['city']:
                    enhanced = {
                        'botResponse': f"Got it, your blood group is {sess['bloodType']}. Which city are you in?",
                        'quickActions': ['Bangalore', 'Delhi', 'Mumbai', 'Hyderabad', 'Chennai'],
                        'next': 'city'
                    }
                    # Mark that we're waiting for city so a short city reply completes the flow
                    sess['awaiting'] = 'city'
                elif sess['bloodType'] and sess['city'] and not sess['urgency']:
                    enhanced = {
                        'botResponse': 'Thanks. How urgent is it? Choose one: Critical, Urgent, Normal.',
                        'quickActions': ['Critical', 'Urgent', 'Normal'],
                        'next': 'urgency'
                    }
                    sess['awaiting'] = 'urgency'

            # Decide whether to run donor matching now
            run_donor_match = False
            run_blood_bank_search = False
            run_contact_donors = False
            
            if enhanced is None:
                # Check for blood bank specific query
                if blood_bank_hint:
                    run_blood_bank_search = True
                # Contact donors hint
                elif contact_hint:
                    run_contact_donors = True
                # 1) Explicit ask or clear donor-related hint in current message
                elif intent == 'find_donors' or find_donors_hint:
                    run_donor_match = True
                # 2) We were explicitly awaiting a slot and this message likely
                #    provided it; if after updating slots we have all required
                #    values, complete the flow once.
                elif sess.get('awaiting') in ('city', 'urgency') and \
                     (sess.get('bloodType') or blood_type) and \
                     (sess.get('city') or city_text) and \
                     (sess.get('urgency') or urgency):
                    run_donor_match = True

            # Live donor matching only when requested/expected, not merely
            # because old slots exist (prevents same reply for every query).
            if enhanced is None and run_donor_match:
                # Prefer blood type from current message, fallback to session-stored blood type
                use_blood_type = blood_type or sess.get('bloodType')
                if not use_blood_type:
                    # If blood type not found in message or session, ask user to provide it
                    enhanced = {
                        'botResponse': 'Please provide a blood type (e.g., O+, A-, etc.) and your city (e.g., Bangalore).',
                        'matches': []
                    }
                else:
                    # prefer session city if available
                    use_city = sess.get('city') or city_text or 'Delhi'
                    use_urgency = (sess.get('urgency') or urgency or 'Normal').capitalize()
                    location = geocode_city(use_city)
                    # Query compatible donors from DB
                    compatible = BLOOD_COMPATIBILITY.get(use_blood_type, [use_blood_type])
                    donors = Donor.query.filter(
                        Donor.blood_type.in_(compatible),
                        Donor.available_for_donation == True
                    ).all()
                    donor_dicts = [d.to_dict() for d in donors]
                    matches = matching_engine.find_best_matches(
                        donor_dicts, location, use_urgency, use_blood_type, limit=10
                    )
                    # Transform summary for chat
                    transformed = []
                    for m in matches:
                        d = m.get('donor', {})
                        transformed.append({
                            'name': d.get('name'),
                            'blood_group': d.get('bloodType'),
                            'city': (d.get('address') or {}).get('city'),
                            'distance_km': m.get('distance'),
                            'score': m.get('matchScore'),
                            'phone': d.get('phone')
                        })
                    if transformed:
                        top = transformed[:3]
                        lines = [f"• {t['name']} {t.get('phone', 'N/A')} ({t['blood_group']}) - {t['distance_km']:.1f} km, score {t['score']}" for t in top]
                        msg = "Here are nearby donor matches:\n" + "\n".join(lines) + "\n\nWould you like me to: Contact top donors, or Check blood banks?"
                    else:
                        msg = "I couldn't find donors nearby right now. Try increasing distance or checking blood banks."
                    enhanced = {
                        'botResponse': msg,
                        'matches': transformed,
                        'quickActions': ['Contact Top Donors', 'Check Blood Banks']
                    }
                    # We've completed the donor intent; stop awaiting to
                    # prevent re-triggering on unrelated messages.
                    sess['awaiting'] = None

            # Handle "Contact Top Donors" action - Only show donors with high match scores (>= 75)
            if enhanced is None and run_contact_donors:
                use_blood_type = blood_type or sess.get('bloodType')
                use_city = sess.get('city') or city_text or 'Delhi'
                use_urgency = (sess.get('urgency') or urgency or 'Normal').capitalize()
                
                if not use_blood_type:
                    enhanced = {
                        'botResponse': 'Please specify a blood type to find donors.',
                        'matches': []
                    }
                else:
                    location = geocode_city(use_city)
                    compatible = BLOOD_COMPATIBILITY.get(use_blood_type, [use_blood_type])
                    donors = Donor.query.filter(
                        Donor.blood_type.in_(compatible),
                        Donor.available_for_donation == True
                    ).all()
                    donor_dicts = [d.to_dict() for d in donors]
                    # Get all matches first
                    all_matches = matching_engine.find_best_matches(
                        donor_dicts, location, use_urgency, use_blood_type, limit=50
                    )
                    
                    # Filter only high-score donors (>= 75)
                    high_score_matches = [m for m in all_matches if m.get('matchScore', 0) >= 75]
                    
                    if high_score_matches:
                        lines = []
                        for m in high_score_matches[:5]:  # Show top 5 high-score donors
                            d = m.get('donor', {})
                            name = d.get('name', 'Unknown')
                            phone = d.get('phone', 'N/A')
                            bg = d.get('bloodType', use_blood_type)
                            dist = m.get('distance', 0)
                            score = m.get('matchScore', 0)
                            lines.append(f"📞 {name}: {phone} ({bg}) - {dist:.1f} km, score {score}")
                        msg = f"Top {len(high_score_matches[:5])} high-score donors (score ≥ 75):\n" + "\n".join(lines)
                    else:
                        msg = "No high-score donors available right now (score ≥ 75). Try blood banks instead."
                    
                    enhanced = {
                        'botResponse': msg,
                        'quickActions': ['Find Donors', 'Blood Banks']
                    }

            # Handle blood bank search
            if enhanced is None and run_blood_bank_search:
                use_blood_type = blood_type or sess.get('bloodType')
                use_city = sess.get('city') or city_text
                
                # Exclude invalid "cities" that are actually command phrases or help keywords
                invalid_cities = ['blood bank', 'blood banks', 'find donor', 'find donors', 'check inventory', 
                                 'contact', 'register', 'hospitals', 'help', 'hi', 'hello', 'hey']
                if use_city and any(inv in use_city.lower() for inv in invalid_cities):
                    use_city = None
                    # Also clear from session
                    sess['city'] = None
                
                # If no filters provided, show all blood banks (popular cities)
                if not use_blood_type and not use_city:
                    # Show blood banks from all cities
                    banks_results = BloodBank.query.limit(20).all()
                    banks = []
                    for b in banks_results:
                        banks.append({
                            'name': b.name,
                            'city': b.city,
                            'state': b.state,
                            'phone': b.phone,
                            'distance_km': None,
                            'available_units': 'Multiple types available'
                        })
                    
                    if banks:
                        # Group by city to show variety
                        by_city = {}
                        for b in banks:
                            city = b['city']
                            if city not in by_city:
                                by_city[city] = []
                            by_city[city].append(b)
                        
                        lines = []
                        count = 0
                        for city, city_banks in list(by_city.items())[:5]:
                            bank = city_banks[0]
                            phone_str = f"📞 {bank['phone']}" if bank.get('phone') else ""
                            lines.append(f"🏥 {bank['name']} ({city}) {phone_str}")
                            count += 1
                        
                        total_cities = len(by_city)
                        msg = f"Available blood banks in {total_cities} cities:\n" + "\n".join(lines)
                        msg += f"\n\n💡 Tip: Specify a city (e.g., 'Bangalore') or blood type (e.g., 'O+') for more targeted results."
                    else:
                        msg = "No blood banks found in database. Try another search."
                    
                    enhanced = {
                        'botResponse': msg,
                        'inventory': banks,
                        'quickActions': ['Bangalore', 'Mumbai', 'Delhi', 'Chennai']
                    }
                else:
                    location = geocode_city(use_city or 'Delhi')
                    
                    # Query blood banks
                    query = BloodBank.query
                    if use_city:
                        # Handle city name variations
                        search_city = use_city
                        if 'bengaluru' in use_city.lower():
                            search_city = 'Bangalore'
                        query = query.filter(BloodBank.city.ilike(f'%{search_city}%'))
                    
                    if use_blood_type:
                        colmap = {
                            'A+': 'inventory_a_positive','A-': 'inventory_a_negative',
                            'B+': 'inventory_b_positive','B-': 'inventory_b_negative',
                            'AB+': 'inventory_ab_positive','AB-': 'inventory_ab_negative',
                            'O+': 'inventory_o_positive','O-': 'inventory_o_negative'
                        }
                        column = colmap.get(use_blood_type)
                        if column:
                            query = query.filter(getattr(BloodBank, column) > 0)
                    
                    banks_results = query.limit(10).all()
                    banks = []
                    for b in banks_results:
                        try:
                            dist = maps_service.calculate_distance(
                                (location['latitude'], location['longitude']),
                                (float(b.latitude), float(b.longitude))
                            )
                        except Exception:
                            dist = None
                        
                        units = 0
                        if use_blood_type and column:
                            units = getattr(b, column, 0)
                        
                        banks.append({
                            'name': b.name,
                            'city': b.city,
                            'state': b.state,
                            'phone': b.phone,
                            'distance_km': dist,
                            'available_units': units if use_blood_type else 'Multiple'
                        })
                    
                    banks.sort(key=lambda x: (x['distance_km'] if x['distance_km'] is not None else 9999))
                    
                    if banks:
                        top = banks[:3]
                        lines = []
                        for t in top:
                            units_str = f"{t['available_units']} units" if isinstance(t['available_units'], int) else "Available"
                            phone_str = f"📞 {t['phone']}" if t.get('phone') else ""
                            dist_str = f"{t['distance_km']:.1f} km" if t['distance_km'] else "N/A"
                            lines.append(f"🏥 {t['name']} ({t['city']}) - {units_str}, {dist_str} {phone_str}")
                        msg = "Available blood banks:\n" + "\n".join(lines)
                    else:
                        msg = f"No blood banks found {'in ' + use_city if use_city else 'nearby'}. Try another city or find donors."
                    
                    enhanced = {
                        'botResponse': msg,
                        'inventory': banks,
                        'quickActions': ['Find Donors', 'Check Inventory']
                    }

            # Inventory lookup when intent suggests availability/stock
            if enhanced is None and (intent == 'inventory' or inventory_hint):
                if not blood_type:
                    enhanced = {
                        'botResponse': 'Please specify a blood group (e.g., O+) and city (e.g., Delhi) to check inventory.',
                        'inventory': []
                    }
                else:
                    location = geocode_city(city_text or 'Delhi')
                    # Map blood type to BloodBank columns
                    colmap = {
                        'A+': 'inventory_a_positive','A-': 'inventory_a_negative',
                        'B+': 'inventory_b_positive','B-': 'inventory_b_negative',
                        'AB+': 'inventory_ab_positive','AB-': 'inventory_ab_negative',
                        'O+': 'inventory_o_positive','O-': 'inventory_o_negative'
                    }
                    column = colmap.get(blood_type)
                    banks = []
                    if column:
                        q = BloodBank.query.filter(getattr(BloodBank, column) > 0).all()
                        for b in q:
                            try:
                                dist = maps_service.calculate_distance(
                                    (location['latitude'], location['longitude']),
                                    (float(b.latitude), float(b.longitude))
                                )
                            except Exception:
                                dist = None
                            banks.append({
                                'name': b.name,
                                'city': b.city,
                                'state': b.state,
                                'distance_km': dist,
                                'available_units': getattr(b, column)
                            })
                        banks.sort(key=lambda x: (x['distance_km'] if x['distance_km'] is not None else 9999))
                    if banks:
                        top = banks[:3]
                        lines = [f"• {t['name']} ({t['city']}) - {t['available_units']} units" for t in top]
                        msg = "Nearby blood bank inventory:\n" + "\n".join(lines)
                    else:
                        msg = "I couldn't find available units nearby. Try another city or check donors."
                    enhanced = {
                        'botResponse': msg,
                        'inventory': banks
                    }

            # Hospital lookup
            if enhanced is None and (intent == 'hospitals' or hospital_hint):
                city = city_text or 'Delhi'
                results = Hospital.query.filter(Hospital.city.ilike(f"%{city}%")).limit(5).all()
                items = [{
                    'name': h.name,
                    'city': h.city,
                    'state': h.state,
                    'phone': h.phone
                } for h in results]
                if items:
                    lines = [f"• {i['name']} ({i['city']})" for i in items[:3]]
                    msg = f"Here are hospitals near {city}:\n" + "\n".join(lines)
                else:
                    msg = f"I couldn't find hospitals in {city} right now. Try another nearby area."
                enhanced = {
                    'botResponse': msg,
                    'hospitals': items
                }
        except Exception:
            logging.getLogger('chatbot').exception('Live data enrichment failed')

        if enhanced:
            # Merge enhanced response into the base response
            response.update(enhanced)

        # Add timestamp and normalize response keys so frontend has 'response'
        from datetime import datetime
        response['timestamp'] = datetime.utcnow().isoformat()
        response['userId'] = user_id
        # Include current session slots for debugging/visibility
        try:
            response['session'] = {
                'bloodType': sess.get('bloodType'),
                'city': sess.get('city'),
                'urgency': sess.get('urgency')
            }
        except Exception:
            response['session'] = None
        # Some clients expect 'response' while internal code uses 'botResponse'
        if 'response' not in response and 'botResponse' in response:
            response['response'] = response.get('botResponse')

        # Log the normalized response at debug level
        logging.getLogger('chatbot').debug('Outgoing chatbot response: %s', response)

        # Persist chat history to instance/chat_history.json for simple auditing
        try:
            # ensure instance path exists
            os.makedirs(current_app.instance_path, exist_ok=True)
            history_file = os.path.join(current_app.instance_path, 'chat_history.json')

            history = []
            if os.path.exists(history_file):
                try:
                    with open(history_file, 'r', encoding='utf-8') as f:
                        history = json.load(f) or []
                except Exception:
                    history = []

            entry = {
                'userId': user_id,
                'user_message': message,
                'bot_response': response.get('response') or response.get('botResponse'),
                'timestamp': response.get('timestamp')
            }
            history.append(entry)
            with open(history_file, 'w', encoding='utf-8') as f:
                json.dump(history, f, ensure_ascii=False, indent=2)
        except Exception as _e:
            logging.getLogger('chatbot').warning('Failed to persist chat history: %s', _e)

        return jsonify({
            'success': True,
            'data': response
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@chatbot_bp.route('/suggestions', methods=['GET'])
def get_suggestions():
    """Get chatbot query suggestions"""
    try:
        suggestions = chatbot.get_suggestions()
        
        return jsonify({
            'success': True,
            'data': suggestions
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@chatbot_bp.route('/reset-session', methods=['POST'])
def reset_session():
    """Clear chatbot session memory.

    Body params:
      - userId: clears only that user's session (default: 'guest')
      - all: when true, clears all sessions
    """
    try:
        data = request.get_json(silent=True) or {}
        if data.get('all') is True:
            _user_sessions.clear()
            return jsonify({'success': True, 'message': 'All chatbot sessions cleared'})
        user_id = data.get('userId') or data.get('user_id') or 'guest'
        if user_id in _user_sessions:
            _user_sessions.pop(user_id, None)
        return jsonify({'success': True, 'message': f'Session cleared for {user_id}'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
