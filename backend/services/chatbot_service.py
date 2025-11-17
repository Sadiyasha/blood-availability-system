"""
Chatbot Service using NLP
Alternative to Dialogflow/Rasa using NLTK and pattern matching
"""

import re
import random

# IMPORTANT: Avoid importing nltk at module import time on minimal servers.
# Some NLTK entrypoints import scipy transitively which is heavy. We default
# to lightweight regex tokenization and a small stopword set. If you want to
# enable NLTK, set the env var USE_NLTK=1 and ensure scipy is installed.
import os
NLTK_AVAILABLE = os.getenv('USE_NLTK', '0') in ('1', 'true', 'True')
if NLTK_AVAILABLE:
    try:
        from nltk.tokenize import word_tokenize  # type: ignore
        from nltk.corpus import stopwords  # type: ignore
    except Exception:
        NLTK_AVAILABLE = False


class BloodDonationChatbot:
    """Intelligent chatbot for blood donation queries"""
    
    def __init__(self):
        # Initialize stop words with robust fallback
        self.stop_words = set()
        if NLTK_AVAILABLE:
            try:
                self.stop_words = set(stopwords.words('english'))
            except Exception:
                # Minimal common stopwords as a safe fallback
                self.stop_words = self._fallback_stopwords()
        else:
            self.stop_words = self._fallback_stopwords()
        self.intents = self._load_intents()

    def _fallback_stopwords(self):
        return {
            'the','is','at','of','on','and','a','to','in','for','with','as','by','an','be','or','are','was','were','it','that','this','from'
        }
    
    def _load_intents(self):
        """Load chatbot intents and responses"""
        return {
            'greeting': {
                'patterns': ['hello', 'hi', 'hey', 'greetings', 'good morning', 'good evening', 'namaste'],
                'responses': [
                    'Hello! I\'m here to help you with blood donation queries. How can I assist you today?',
                    'Hi there! I can help you find blood donors, blood banks, or answer questions about blood donation. What would you like to know?',
                    'Welcome to Blood Availability System! Ask me anything about blood donation, donors, or blood banks.'
                ]
            },
            'inventory': {
                'patterns': ['availability', 'stock', 'units', 'inventory', 'have o+', 'need stock', 'blood available'],
                'responses': [
                    'I can check blood bank inventory. Tell me the blood group (e.g., O+) and city (e.g., Delhi).'
                ]
            },
            'hospitals': {
                'patterns': ['hospital', 'nearest hospital', 'hospitals near', 'emergency hospital', 'icu'],
                'responses': [
                    'I can find nearby hospitals. Tell me your city (e.g., Bangalore) or say "near me".'
                ]
            },
            'eligibility': {
                'patterns': ['eligible', 'can i donate', 'eligibility', 'who can donate', 'requirements', 'qualify'],
                'responses': [
                    'To donate blood, you must be:\n✓ 18-65 years old\n✓ Weight at least 50 kg\n✓ In good health\n✓ Not donated blood in last 3 months\n✓ No chronic diseases or infections\n\nWould you like to register as a donor?'
                ]
            },
            'blood_types': {
                'patterns': ['blood type', 'blood group', 'compatible', 'compatibility', 'o+', 'a+', 'b+', 'ab+', 'o-', 'a-', 'b-', 'ab-', 'universal'],
                'responses': [
                    'Blood Type Compatibility:\n\n🅾️ O- (Universal Donor): Can donate to all blood types\n🆎 AB+ (Universal Recipient): Can receive from all blood types\n\n✓ A+ can receive: A+, A-, O+, O-\n✓ A- can receive: A-, O-\n✓ B+ can receive: B+, B-, O+, O-\n✓ B- can receive: B-, O-\n✓ AB+ can receive: All blood types\n✓ AB- can receive: A-, B-, AB-, O-\n✓ O+ can receive: O+, O-\n✓ O- can receive: O-\n\nWhat\'s your blood type?'
                ]
            },
            'find_donors': {
                'patterns': ['find donor', 'need blood', 'search donor', 'looking for donor', 'urgent blood', 'require blood'],
                'responses': [
                    'I can help you find blood donors! Please provide:\n\n1️⃣ Required blood type (e.g., O+, A-, etc.)\n2️⃣ Your location (city/area)\n3️⃣ Urgency level (Critical/Urgent/Normal)\n\nYou can use our Smart Match feature to find the best donors near you!'
                ]
            },
            'blood_banks': {
                'patterns': ['blood bank', 'blood banks', 'where can i find', 'nearest blood bank', 'bank location'],
                'responses': [
                    'You can find blood banks through our system:\n\n📍 Use the Map feature to see nearby blood banks\n🔍 Search by city or area\n📊 Check real-time blood inventory\n📞 Get contact information\n\nWould you like to search for blood banks in your area?'
                ]
            },
            'donation_process': {
                'patterns': ['donation process', 'how to donate', 'donation steps', 'what happens', 'procedure', 'process'],
                'responses': [
                    'Blood Donation Process:\n\n1️⃣ Registration & Health Screening\n2️⃣ Medical History Check\n3️⃣ Physical Examination (BP, Hemoglobin)\n4️⃣ Blood Collection (10-15 minutes)\n5️⃣ Rest & Refreshments\n6️⃣ Receive Donation Certificate\n\n💉 Total time: 30-45 minutes\n🩸 One donation can save 3 lives!\n\nReady to donate?'
                ]
            },
            'benefits': {
                'patterns': ['benefits', 'why donate', 'advantages', 'good for health', 'why should'],
                'responses': [
                    'Benefits of Blood Donation:\n\n❤️ Health Benefits:\n• Free health screening\n• Reduces risk of heart disease\n• Burns calories\n• Stimulates blood cell production\n\n🌟 Social Benefits:\n• Saves lives\n• Helps community\n• Emergency blood availability\n• Get donor recognition\n\nDonate blood, save lives!'
                ]
            },
            'emergency': {
                'patterns': ['emergency', 'urgent', 'critical', 'immediately', 'asap', 'life threatening', '911', '102'],
                'responses': [
                    '🚨 EMERGENCY BLOOD NEEDED?\n\n⚡ Quick Actions:\n1️⃣ Use Smart Match for instant donor search\n2️⃣ Contact nearest blood bank: Available 24/7\n3️⃣ Call emergency: 102 (Ambulance)\n4️⃣ Check nearby hospitals with blood banks\n\n📞 Need immediate help? Contact us at emergency helpline.\n\nStay calm, help is on the way!'
                ]
            },
            'contact': {
                'patterns': ['contact', 'help', 'support', 'phone number', 'email', 'reach', 'call'],
                'responses': [
                    '📞 Contact Information:\n\n🏥 Emergency Helpline: 102\n📧 Email: support@bloodsystem.in\n📱 Phone: +91-XXXX-XXXXXX\n⏰ Available: 24/7\n\n💬 You can also:\n• Use in-app chat\n• Visit nearest blood bank\n• Call any listed hospital\n\nHow can we help you today?'
                ]
            },
            'thanks': {
                'patterns': ['thank', 'thanks', 'appreciate', 'helpful', 'great', 'awesome'],
                'responses': [
                    'You\'re welcome! Happy to help. Remember, every blood donation saves lives! 🩸❤️',
                    'Glad I could help! Feel free to ask if you have more questions about blood donation.',
                    'Thank you for using our system! Together we can save more lives. 🙏'
                ]
            }
        }
    
    def preprocess_text(self, text):
        """Preprocess user input"""
        # Convert to lowercase
        text = text.lower().strip()
        
        # Tokenize with fallback
        if NLTK_AVAILABLE:
            try:
                tokens = word_tokenize(text)
            except Exception:
                tokens = re.split(r"\W+", text)
        else:
            tokens = re.split(r"\W+", text)
        
        # Remove stopwords
        filtered_tokens = [w for w in tokens if w and (w not in self.stop_words)]
        
        return text, filtered_tokens
    
    def match_intent(self, text, tokens):
        """Match user input to an intent"""
        best_match = None
        max_matches = 0
        
        for intent_name, intent_data in self.intents.items():
            matches = 0
            for pattern in intent_data['patterns']:
                if pattern in text:
                    matches += 10  # Exact phrase match
                elif any(pattern_word in tokens for pattern_word in pattern.split()):
                    matches += 1  # Word match
            
            if matches > max_matches:
                max_matches = matches
                best_match = intent_name
        
        return best_match if max_matches > 0 else 'default'
    
    def get_response(self, user_message):
        """Get chatbot response for user message"""
        text, tokens = self.preprocess_text(user_message)
        intent = self.match_intent(text, tokens)
        
        # Get response
        if intent in self.intents:
            responses = self.intents[intent]['responses']
            response = random.choice(responses)
        else:
            response = self._get_default_response()
        
        # Generate quick actions
        quick_actions = self._get_quick_actions(intent)
        
        return {
            'userMessage': user_message,
            'botResponse': response,
            'intent': intent,
            'quickActions': quick_actions,
            'confidence': 0.85 if intent != 'default' else 0.5
        }
    
    def _get_default_response(self):
        """Get default response when no intent matches"""
        return ('I can help you with:\n\n'
                '🔍 Finding blood donors\n'
                '🏥 Locating blood banks\n'
                '📋 Blood donation eligibility\n'
                '🩸 Blood type compatibility\n'
                '❓ Donation process & benefits\n'
                '🚨 Emergency blood requests\n\n'
                'What would you like to know?')
    
    def _get_quick_actions(self, intent):
        """Get quick action buttons based on intent"""
        quick_actions_map = {
            'find_donors': ['Find Donors', 'Blood Banks', 'Emergency'],
            'inventory': ['Check Inventory', 'Blood Banks', 'Find Donors'],
            'hospitals': ['Nearest Hospital', 'View Map', 'Emergency'],
            'blood_banks': ['View Map', 'Search Banks', 'Check Inventory'],
            'eligibility': ['Register as Donor', 'Check Eligibility', 'Learn More'],
            'emergency': ['Smart Match', 'Nearest Hospital', 'Call Emergency'],
            'default': ['Find Donors', 'Blood Banks', 'Register']
        }
        
        return quick_actions_map.get(intent, ['Find Donors', 'Blood Banks', 'Help'])
    
    def get_suggestions(self):
        """Get suggested questions"""
        return [
            'How do I find blood donors?',
            'What are the blood donation requirements?',
            'Where is the nearest blood bank?',
            'Blood type compatibility chart',
            'I need blood urgently',
            'How often can I donate blood?',
            'Benefits of blood donation',
            'Contact emergency helpline'
        ]


# Singleton instance
chatbot = BloodDonationChatbot()
