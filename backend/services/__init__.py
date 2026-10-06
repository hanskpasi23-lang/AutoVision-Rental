"""
AI Damage Analyzer Service
Simulates AI analysis of vehicle inspection images for damage detection.
In production, this would integrate with a real AI/ML service.
"""
import json
import random
from typing import Dict, List, Optional

class AIDamageAnalyzer:
    """Service for analyzing vehicle images for damage detection"""
    
    SEVERITY_CONFIG = {
        'none': {'credit_adjustment': 5, 'description': 'No damage detected'},
        'minor': {'credit_adjustment': -10, 'description': 'Minor scratches or scuffs'},
        'moderate': {'credit_adjustment': -25, 'description': 'Moderate dents or paint damage'},
        'severe': {'credit_adjustment': -50, 'description': 'Severe damage requiring repair'}
    }
    
    def analyze_pre_rental(self, images: Dict[str, str]) -> Dict:
        """
        Analyze pre-rental inspection images for existing damage.
        
        Args:
            images: Dict with keys 'front', 'back', 'left', 'right' containing image paths/URLs
            
        Returns:
            Analysis result with damage detection status
        """
        
        damage_found = random.random() < 0.15
        
        if damage_found:
            damage_locations = random.sample(['front', 'back', 'left', 'right'], 
                                            k=random.randint(1, 2))
            damage_types = ['scratch', 'dent', 'paint chip', 'scuff']
            
            damage_details = []
            for location in damage_locations:
                damage_details.append({
                    'location': location,
                    'type': random.choice(damage_types),
                    'severity': random.choice(['minor', 'moderate']),
                    'description': f"Existing {random.choice(damage_types)} detected on {location} of vehicle"
                })
            
            return {
                'damage_detected': True,
                'can_proceed': True,
                'damage_count': len(damage_details),
                'damage_details': damage_details,
                'summary': f"Pre-existing damage detected in {len(damage_details)} area(s). This has been documented for your reference.",
                'recommendation': 'You may proceed with the rental. Any pre-existing damage has been recorded.'
            }
        else:
            return {
                'damage_detected': False,
                'can_proceed': True,
                'damage_count': 0,
                'damage_details': [],
                'summary': 'Vehicle inspection complete. No pre-existing damage detected.',
                'recommendation': 'Vehicle is in excellent condition. You may proceed with the rental.'
            }
    
    def analyze_post_rental(self, 
                           pre_images: Dict[str, str], 
                           post_images: Dict[str, str],
                           pre_analysis: Optional[Dict] = None) -> Dict:
        """
        Compare pre and post rental images to detect new damage.
        
        Args:
            pre_images: Pre-rental inspection images
            post_images: Post-rental inspection images
            pre_analysis: Previous analysis results for reference
            
        Returns:
            Comparison result with severity grading
        """
        
        new_damage = random.random() < 0.2
        
        if new_damage:
            severity_roll = random.random()
            if severity_roll < 0.5:
                severity = 'minor'
            elif severity_roll < 0.85:
                severity = 'moderate'
            else:
                severity = 'severe'
            
            damage_location = random.choice(['front', 'back', 'left', 'right'])
            damage_type = random.choice(['scratch', 'dent', 'paint chip', 'crack'])
            
            severity_info = self.SEVERITY_CONFIG[severity]
            
            cost_estimates = {
                'minor': random.uniform(50, 150),
                'moderate': random.uniform(200, 500),
                'severe': random.uniform(800, 2000)
            }
            
            return {
                'new_damage_detected': True,
                'severity_grade': severity,
                'credit_adjustment': severity_info['credit_adjustment'],
                'damage_cost_estimate': round(cost_estimates[severity], 2),
                'damage_details': [{
                    'location': damage_location,
                    'type': damage_type,
                    'severity': severity,
                    'description': f"New {damage_type} detected on {damage_location}"
                }],
                'summary': f"New {severity} damage detected: {damage_type} on {damage_location}. {severity_info['description']}.",
                'comparison_notes': 'Damage was not present in pre-rental inspection images.'
            }
        else:
            severity_info = self.SEVERITY_CONFIG['none']
            return {
                'new_damage_detected': False,
                'severity_grade': 'none',
                'credit_adjustment': severity_info['credit_adjustment'],
                'damage_cost_estimate': 0,
                'damage_details': [],
                'summary': 'Excellent! Vehicle returned in the same condition as received.',
                'comparison_notes': 'No new damage detected compared to pre-rental inspection.'
            }
    
    def get_severity_description(self, severity: str) -> str:
        """Get human-readable description for a severity grade"""
        return self.SEVERITY_CONFIG.get(severity, {}).get('description', 'Unknown severity')
    
    def get_credit_adjustment(self, severity: str) -> float:
        """Get credit score adjustment for a severity grade"""
        return self.SEVERITY_CONFIG.get(severity, {}).get('credit_adjustment', 0)

damage_analyzer = AIDamageAnalyzer()
