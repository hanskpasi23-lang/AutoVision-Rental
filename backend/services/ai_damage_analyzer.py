"""
AI Damage Analyzer Service — Offline 3-Stage Pipeline
=====================================================
Stage 1: Image Validator   (MobileNetV2)  — Rejects non-vehicle images
Stage 2: Vehicle Matcher   (ResNet18)     — Verifies make/model matches booked vehicle
Stage 3: Damage Detector   (YOLOv8)       — Detects damage with measurements & severity

All models run locally. No API keys required.
Place model weights in backend/ml_models/:
  - image_validator.pt   (MobileNetV2 fine-tuned)
  - vehicle_matcher.pt   (ResNet18 fine-tuned)
  - damage_detector.pt   (YOLOv8 trained)
"""

import os
import logging
import math
import random
from typing import Dict, List, Optional, Tuple
from PIL import Image

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

ML_MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "ml_models")
UPLOADS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")

class ImageValidator:
    """MobileNetV2-based classifier: vehicle vs non-vehicle."""

    LABELS = ["non_vehicle", "vehicle"]

    def __init__(self):
        self.model = None
        self.transform = None
        self._load()

    def _load(self):
        model_path = os.path.join(ML_MODELS_DIR, "image_validator.pt")
        if not os.path.exists(model_path):
            logger.warning("image_validator.pt not found — Stage 1 will be SKIPPED.")
            return

        try:
            import torch
            import torchvision.transforms as T

            self.model = torch.load(model_path, map_location="cpu", weights_only=False)
            self.model.eval()
            self.transform = T.Compose([
                T.Resize((224, 224)),
                T.ToTensor(),
                T.Normalize(mean=[0.485, 0.456, 0.406],
                            std=[0.229, 0.224, 0.225]),
            ])
            logger.info("✅ Image Validator loaded.")
        except Exception as e:
            logger.error(f"Failed to load Image Validator: {e}")

    def validate(self, image_path: str) -> Dict:
        """Returns {is_vehicle: bool, confidence: float}."""
        if self.model is None:
            return {"is_vehicle": True, "confidence": 1.0, "skipped": True}

        import torch

        img = Image.open(image_path).convert("RGB")
        tensor = self.transform(img).unsqueeze(0)

        with torch.no_grad():
            output = self.model(tensor)
            probabilities = torch.softmax(output, dim=1)[0]
            vehicle_prob = probabilities[1].item()

        return {
            "is_vehicle": vehicle_prob >= 0.7,
            "confidence": round(vehicle_prob, 4),
            "skipped": False,
        }

class AngleValidator:
    """Simulated classifier: verifies if image matches expected angle (front, back, etc.)."""
    
    def __init__(self):
        logger.info("✅ Angle Validator (Simulated) loaded.")
        
    def validate(self, image_path: str, expected_angle: str) -> Dict:
        """
        Returns {is_correct_angle: bool, confidence: float}.
        For demonstration purposes, this has an 85% success rate.
        """
        is_correct = random.random() > 0.15
        
        return {
            "is_correct_angle": is_correct,
            "confidence": round(random.uniform(0.75, 0.98), 2)
        }

class VehicleMatcher:
    """ResNet18-based classifier: predicts vehicle make + model."""

    def __init__(self):
        self.model = None
        self.transform = None
        self.class_names: List[str] = []
        self._load()

    def _load(self):
        model_path = os.path.join(ML_MODELS_DIR, "vehicle_matcher.pt")
        labels_path = os.path.join(ML_MODELS_DIR, "vehicle_labels.txt")
        if not os.path.exists(model_path):
            logger.warning("vehicle_matcher.pt not found — Stage 2 will be SKIPPED.")
            return

        try:
            import torch
            import torchvision.transforms as T

            self.model = torch.load(model_path, map_location="cpu", weights_only=False)
            self.model.eval()
            self.transform = T.Compose([
                T.Resize((224, 224)),
                T.ToTensor(),
                T.Normalize(mean=[0.485, 0.456, 0.406],
                            std=[0.229, 0.224, 0.225]),
            ])

            if os.path.exists(labels_path):
                with open(labels_path, "r") as f:
                    self.class_names = [line.strip() for line in f.readlines()]
            else:
                logger.warning("vehicle_labels.txt not found — matcher will return index only.")

            logger.info(f"✅ Vehicle Matcher loaded ({len(self.class_names)} classes).")
        except Exception as e:
            logger.error(f"Failed to load Vehicle Matcher: {e}")

    def match(self, image_path: str, expected_make: str, expected_model: str) -> Dict:
        """
        Returns {matches: bool, detected: str, expected: str, confidence: float}.
        """
        if self.model is None:
            return {"matches": True, "detected": "unknown", "expected": f"{expected_make} {expected_model}",
                    "confidence": 1.0, "skipped": True}

        import torch

        img = Image.open(image_path).convert("RGB")
        tensor = self.transform(img).unsqueeze(0)

        with torch.no_grad():
            output = self.model(tensor)
            probabilities = torch.softmax(output, dim=1)[0]
            top_idx = torch.argmax(probabilities).item()
            top_conf = probabilities[top_idx].item()

        detected = self.class_names[top_idx] if top_idx < len(self.class_names) else f"class_{top_idx}"
        expected = f"{expected_make} {expected_model}".lower().strip()

        detected_lower = detected.lower()
        make_match = expected_make.lower() in detected_lower
        model_match = expected_model.lower() in detected_lower
        matches = (make_match or model_match) and top_conf >= 0.5

        return {
            "matches": matches,
            "detected": detected,
            "expected": expected,
            "confidence": round(top_conf, 4),
            "skipped": False,
        }

class DamageDetector:
    """YOLOv8-based damage detection with measurements."""

    REFERENCE_SIZES = {
        "bumper": 180,
        "door": 120,
        "hood": 140,
        "fender": 80,
        "quarter_panel": 100,
        "default": 120,
    }

    def __init__(self):
        self.model = None
        self._load()

    def _load(self):
        model_path = os.path.join(ML_MODELS_DIR, "damage_detector.pt")
        if not os.path.exists(model_path):
            logger.warning("damage_detector.pt not found — Stage 3 will be SKIPPED (mock mode).")
            return

        try:
            from ultralytics import YOLO
            self.model = YOLO(model_path)
            logger.info("✅ Damage Detector loaded.")
        except Exception as e:
            logger.error(f"Failed to load Damage Detector: {e}")

    def _estimate_size_cm(self, bbox_w_px: float, bbox_h_px: float,
                          img_w: int, img_h: int, part: str = "default") -> Tuple[float, float]:
        """Estimate damage dimensions in cm using vehicle part proportions."""
        ref_cm = self.REFERENCE_SIZES.get(part, self.REFERENCE_SIZES["default"])
        vehicle_width_px = img_w * 0.8
        px_per_cm = vehicle_width_px / ref_cm
        if px_per_cm == 0:
            return (0.0, 0.0)
        return (round(bbox_w_px / px_per_cm, 1), round(bbox_h_px / px_per_cm, 1))

    def _grade_severity(self, damages: List[Dict]) -> str:
        """Determine overall severity from list of detected damages."""
        if not damages:
            return "none"

        max_area = max(d.get("area_cm2", 0) for d in damages)
        types = [d.get("type", "").lower() for d in damages]

        if "crack" in types or "glass_crack" in types or max_area > 500:
            return "severe"
        elif "dent" in types or max_area > 100:
            return "moderate"
        elif max_area > 0:
            return "minor"
        return "none"

    def _estimate_cost(self, severity: str, damage_count: int) -> float:
        """Estimate repair cost based on severity."""
        base_costs = {"none": 0, "minor": 75, "moderate": 350, "severe": 1200}
        return round(base_costs.get(severity, 0) * max(1, damage_count * 0.7), 2)

    def detect(self, image_path: str) -> List[Dict]:
        """Run damage detection on a single image."""
        if self.model is None:
            return []

        img = Image.open(image_path)
        img_w, img_h = img.size
        results = self.model(image_path, verbose=False)

        detections = []
        for r in results:
            for box in r.boxes:
                cls_id = int(box.cls[0])
                cls_name = r.names.get(cls_id, f"damage_{cls_id}")
                conf = float(box.conf[0])

                x1, y1, x2, y2 = box.xyxy[0].tolist()
                bbox_w = x2 - x1
                bbox_h = y2 - y1
                w_cm, h_cm = self._estimate_size_cm(bbox_w, bbox_h, img_w, img_h)
                area_cm2 = round(w_cm * h_cm, 1)

                detections.append({
                    "type": cls_name,
                    "confidence": round(conf, 4),
                    "bbox": [round(x1), round(y1), round(x2), round(y2)],
                    "width_cm": w_cm,
                    "height_cm": h_cm,
                    "area_cm2": area_cm2,
                    "description": (
                        f"{cls_name.replace('_', ' ').title()} — "
                        f"approximately {w_cm}cm × {h_cm}cm "
                        f"(area ≈ {area_cm2}cm²)"
                    ),
                })

        return detections

class AIDamageAnalyzer:
    """Three-stage offline AI pipeline for vehicle inspections."""

    SEVERITY_CONFIG = {
        "none":     {"credit_adjustment":   5, "description": "No damage detected"},
        "minor":    {"credit_adjustment": -10, "description": "Minor scratches or scuffs"},
        "moderate": {"credit_adjustment": -25, "description": "Moderate dents or paint damage"},
        "severe":   {"credit_adjustment": -50, "description": "Severe structural damage"},
    }

    def __init__(self):
        logger.info("Initializing AI Damage Analyzer (offline pipeline)…")
        self.validator = ImageValidator()
        self.matcher = VehicleMatcher()
        self.detector = DamageDetector()
        logger.info("AI Damage Analyzer ready.")

    def _resolve_path(self, url_or_path: str) -> str:
        """Convert an upload URL like /uploads/inspections/file.jpg to an absolute path."""
        if url_or_path.startswith("/uploads"):
            return os.path.join(UPLOADS_DIR, url_or_path.replace("/uploads/", ""))
        return url_or_path

    def _validate_all_images(self, images: Dict[str, str],
                             vehicle_make: str, vehicle_model: str) -> Optional[Dict]:
        """
        Run Stage 1 + Stage 2 on all images.
        Returns an error dict if validation fails, or None if all pass.
        """
        for angle, url in images.items():
            path = self._resolve_path(url)
            if not os.path.exists(path):
                continue

            v = self.validator.validate(path)
            if not v["is_vehicle"]:
                return {
                    "validation_passed": False,
                    "error": "not_a_vehicle",
                    "failed_angle": angle,
                    "confidence": v["confidence"],
                    "message": (
                        f"The {angle} image does not appear to be a vehicle photo "
                        f"(confidence: {v['confidence']:.0%}). Please re-upload a clear photo of the vehicle."
                    ),
                }

            m = self.matcher.match(path, vehicle_make, vehicle_model)
            if not m["matches"]:
                return {
                    "validation_passed": False,
                    "error": "vehicle_mismatch",
                    "failed_angle": angle,
                    "detected": m["detected"],
                    "expected": m["expected"],
                    "confidence": m["confidence"],
                    "message": (
                        f"The {angle} image does not match the booked vehicle "
                        f"({vehicle_make} {vehicle_model}). "
                        f"Detected: {m['detected']}. Please upload photos of the correct vehicle."
                    ),
                }

        return None

    def _detect_all_damages(self, images: Dict[str, str]) -> Tuple[List[Dict], str]:
        """Run Stage 3 on all images. Returns (damage_details, overall_severity)."""
        all_damages: List[Dict] = []

        for angle, url in images.items():
            path = self._resolve_path(url)
            if not os.path.exists(path):
                continue

            detections = self.detector.detect(path)
            for det in detections:
                det["location"] = angle
                det["description"] = f"{det['description']} on the {angle} side"
                all_damages.append(det)

        severity = self.detector._grade_severity(all_damages)
        return all_damages, severity

    def analyze_pre_rental(self, images: Dict[str, str],
                           vehicle_make: str = "", vehicle_model: str = "",
                           vehicle_year: int = 0) -> Dict:
        """
        Pre-rental inspection analysis.
        Returns validation errors OR damage analysis.
        """
        error = self._validate_all_images(images, vehicle_make, vehicle_model)
        if error:
            return error

        damages, severity = self._detect_all_damages(images)
        damage_count = len(damages)

        return {
            "validation_passed": True,
            "damage_detected": damage_count > 0,
            "can_proceed": damage_count == 0,
            "damage_count": damage_count,
            "damage_details": damages,
            "severity_grade": severity,
            "summary": (
                f"Pre-existing damage detected: {damage_count} issue(s), severity: {severity}."
                if damage_count > 0
                else "Vehicle inspection complete. No pre-existing damage detected."
            ),
            "recommendation": (
                "Vehicle has pre-existing damage and cannot be rented. Please cancel this booking."
                if damage_count > 0
                else "Vehicle is in excellent condition. You may proceed."
            ),
        }

    def analyze_post_rental(self, pre_images: Dict[str, str],
                            post_images: Dict[str, str],
                            pre_analysis: Optional[Dict] = None,
                            vehicle_make: str = "", vehicle_model: str = "",
                            vehicle_year: int = 0) -> Dict:
        """
        Post-rental inspection analysis with comparison.
        Returns validation errors OR damage comparison.
        """
        error = self._validate_all_images(post_images, vehicle_make, vehicle_model)
        if error:
            return error

        post_damages, post_severity = self._detect_all_damages(post_images)

        pre_damage_count = 0
        if pre_analysis and pre_analysis.get("validation_passed", True):
            pre_damage_count = pre_analysis.get("damage_count", 0)

        new_damage_count = max(0, len(post_damages) - pre_damage_count)
        new_damage_detected = new_damage_count > 0

        if not new_damage_detected:
            final_severity = "none"
        else:
            final_severity = post_severity

        severity_info = self.SEVERITY_CONFIG.get(final_severity, self.SEVERITY_CONFIG["none"])
        cost = self.detector._estimate_cost(final_severity, new_damage_count)

        if new_damage_detected:
            comparison = (
                f"{new_damage_count} new damage(s) found compared to pre-rental inspection. "
                f"Total damages now: {len(post_damages)}, pre-existing: {pre_damage_count}."
            )
        else:
            comparison = "No new damage detected compared to pre-rental inspection."

        return {
            "validation_passed": True,
            "new_damage_detected": new_damage_detected,
            "severity_grade": final_severity,
            "credit_adjustment": severity_info["credit_adjustment"],
            "damage_cost_estimate": cost,
            "damage_details": post_damages,
            "new_damage_count": new_damage_count,
            "total_damage_count": len(post_damages),
            "pre_existing_count": pre_damage_count,
            "summary": (
                f"New {final_severity} damage detected: {new_damage_count} issue(s). "
                f"{severity_info['description']}. Estimated repair cost: ${cost:.2f}."
                if new_damage_detected
                else "Excellent! Vehicle returned in the same condition as received."
            ),
            "comparison_notes": comparison,
        }

    def get_severity_description(self, severity: str) -> str:
        return self.SEVERITY_CONFIG.get(severity, {}).get("description", "Unknown severity")

    def get_credit_adjustment(self, severity: str) -> float:
        return self.SEVERITY_CONFIG.get(severity, {}).get("credit_adjustment", 0)

damage_analyzer = AIDamageAnalyzer()
