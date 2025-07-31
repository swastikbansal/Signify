import cv2
import mediapipe as mp
import numpy as np
import math
from typing import List, Dict, Tuple, Optional
import argparse
import os
from collections import deque

class SignLanguageBVHGenerator:
    def __init__(self):
        # Initialize MediaPipe with optimized settings for upper body
        self.mp_pose = mp.solutions.pose
        self.mp_hands = mp.solutions.hands
        self.mp_drawing = mp.solutions.drawing_utils
        
        # MediaPipe models optimized for sign language capture
        self.pose = self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=2,
            enable_segmentation=False,
            min_detection_confidence=0.8,
            min_tracking_confidence=0.8
        )
        
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=2,
            min_detection_confidence=0.8,
            min_tracking_confidence=0.8
        )
        
        # Define MediaPipe landmark indices
        self.pose_landmarks = self._define_pose_landmarks()
        self.hand_landmarks = self._define_hand_landmarks()
        
        # Optimized skeleton hierarchy for sign language
        self.joint_hierarchy = self._create_sign_language_skeleton()
        self.joint_offsets = self._create_realistic_offsets()
        self.frame_data = []
        self.fps = 30
        
        # Enhanced smoothing system
        self.position_history = deque(maxlen=7)
        self.rotation_history = deque(maxlen=5)
        self.torso_reference = None
        self.shoulder_reference = None
        
        # Stabilization parameters
        self.torso_stability_factor = 0.95
        self.shoulder_stability_factor = 0.8
        
    def _define_pose_landmarks(self) -> Dict[str, int]:
        """Define MediaPipe pose landmark indices"""
        return {
            # Face landmarks
            'NOSE': 0, 'LEFT_EYE_INNER': 1, 'LEFT_EYE': 2, 'LEFT_EYE_OUTER': 3,
            'RIGHT_EYE_INNER': 4, 'RIGHT_EYE': 5, 'RIGHT_EYE_OUTER': 6,
            'LEFT_EAR': 7, 'RIGHT_EAR': 8, 'MOUTH_LEFT': 9, 'MOUTH_RIGHT': 10,
            
            # Upper body (most important for sign language)
            'LEFT_SHOULDER': 11, 'RIGHT_SHOULDER': 12,
            'LEFT_ELBOW': 13, 'RIGHT_ELBOW': 14,
            'LEFT_WRIST': 15, 'RIGHT_WRIST': 16,
            'LEFT_PINKY': 17, 'RIGHT_PINKY': 18,
            'LEFT_INDEX': 19, 'RIGHT_INDEX': 20,
            'LEFT_THUMB': 21, 'RIGHT_THUMB': 22,
            
            # Lower body (for reference only)
            'LEFT_HIP': 23, 'RIGHT_HIP': 24,
            'LEFT_KNEE': 25, 'RIGHT_KNEE': 26,
            'LEFT_ANKLE': 27, 'RIGHT_ANKLE': 28,
            'LEFT_HEEL': 29, 'RIGHT_HEEL': 30,
            'LEFT_FOOT_INDEX': 31, 'RIGHT_FOOT_INDEX': 32
        }
    
    def _define_hand_landmarks(self) -> Dict[str, int]:
        """Define MediaPipe hand landmark indices"""
        return {
            'WRIST': 0,
            'THUMB_CMC': 1, 'THUMB_MCP': 2, 'THUMB_IP': 3, 'THUMB_TIP': 4,
            'INDEX_MCP': 5, 'INDEX_PIP': 6, 'INDEX_DIP': 7, 'INDEX_TIP': 8,
            'MIDDLE_MCP': 9, 'MIDDLE_PIP': 10, 'MIDDLE_DIP': 11, 'MIDDLE_TIP': 12,
            'RING_MCP': 13, 'RING_PIP': 14, 'RING_DIP': 15, 'RING_TIP': 16,
            'PINKY_MCP': 17, 'PINKY_PIP': 18, 'PINKY_DIP': 19, 'PINKY_TIP': 20
        }
    
    def _create_sign_language_skeleton(self) -> Dict:
        """Create skeleton optimized for sign language capture"""
        return {
            'Hips': {
                'channels': ['Xposition', 'Yposition', 'Zposition', 'Zrotation', 'Xrotation', 'Yrotation'],
                'children': {
                    # Simplified lower body - completely stabilized
                    'LeftHipJoint': {
                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                        'children': {
                            'LeftUpLeg': {
                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                'children': {
                                    'LeftLeg': {
                                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                        'children': {
                                            'LeftFoot': {
                                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                'children': {}
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    'RightHipJoint': {
                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                        'children': {
                            'RightUpLeg': {
                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                'children': {
                                    'RightLeg': {
                                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                        'children': {
                                            'RightFoot': {
                                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                'children': {}
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    # Optimized spine chain for sign language
                    'Spine': {
                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                        'children': {
                            'Chest': {
                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                'children': {
                                    'Neck': {
                                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                        'children': {
                                            'Head': {
                                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                'children': {}
                                            }
                                        }
                                    },
                                    # Enhanced left arm chain for precise sign language
                                    'LeftShoulder': {
                                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                        'children': {
                                            'LeftArm': {
                                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                'children': {
                                                    'LeftForeArm': {
                                                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                        'children': {
                                                            'LeftHand': {
                                                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                                'children': self._create_detailed_hand_hierarchy('Left')
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    },
                                    # Enhanced right arm chain for precise sign language
                                    'RightShoulder': {
                                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],  
                                        'children': {
                                            'RightArm': {
                                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                'children': {
                                                    'RightForeArm': {
                                                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                        'children': {
                                                            'RightHand': {
                                                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                                                'children': self._create_detailed_hand_hierarchy('Right')
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    
    def _create_detailed_hand_hierarchy(self, side: str) -> Dict:
        """Create detailed hand hierarchy optimized for sign language"""
        return {
            f'{side}HandThumb1': {
                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                'children': {
                    f'{side}HandThumb2': {
                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                        'children': {
                            f'{side}HandThumb3': {
                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                'children': {}
                            }
                        }
                    }
                }
            },
            f'{side}HandIndex1': {
                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                'children': {
                    f'{side}HandIndex2': {
                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                        'children': {
                            f'{side}HandIndex3': {
                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                'children': {}
                            }
                        }
                    }
                }
            },
            f'{side}HandMiddle1': {
                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                'children': {
                    f'{side}HandMiddle2': {
                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                        'children': {
                            f'{side}HandMiddle3': {
                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                'children': {}
                            }
                        }
                    }
                }
            },
            f'{side}HandRing1': {
                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                'children': {
                    f'{side}HandRing2': {
                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                        'children': {
                            f'{side}HandRing3': {
                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                'children': {}
                            }
                        }
                    }
                }
            },
            f'{side}HandPinky1': {
                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                'children': {
                    f'{side}HandPinky2': {
                        'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                        'children': {
                            f'{side}HandPinky3': {
                                'channels': ['Zrotation', 'Xrotation', 'Yrotation'],
                                'children': {}
                            }
                        }
                    }
                }
            }
        }
    
    def _create_realistic_offsets(self) -> Dict[str, Tuple[float, float, float]]:
        """Create realistic proportions optimized for sign language"""
        return {
            # Root
            'Hips': (0.0, 0.0, 0.0),
            
            # Lower body - stabilized
            'LeftHipJoint': (-8.0, 0.0, 0.0),
            'LeftUpLeg': (0.0, -15.0, 0.0),
            'LeftLeg': (0.0, -18.0, 0.0),
            'LeftFoot': (0.0, -6.0, 0.0),
            
            'RightHipJoint': (8.0, 0.0, 0.0),
            'RightUpLeg': (0.0, -15.0, 0.0),
            'RightLeg': (0.0, -18.0, 0.0),
            'RightFoot': (0.0, -6.0, 0.0),
            
            # Optimized spine chain
            'Spine': (0.0, 12.0, 0.0),
            'Chest': (0.0, 15.0, 0.0),
            'Neck': (0.0, 8.0, 0.0),
            'Head': (0.0, 6.0, 0.0),
            
            # Enhanced arm proportions for sign language
            'LeftShoulder': (-12.0, 6.0, -1.0),
            'LeftArm': (-15.0, 0.0, 0.0),
            'LeftForeArm': (-12.0, 0.0, 0.0),
            'LeftHand': (-10.0, 0.0, 0.0),
            
            'RightShoulder': (12.0, 6.0, -1.0),  
            'RightArm': (15.0, 0.0, 0.0),
            'RightForeArm': (12.0, 0.0, 0.0),
            'RightHand': (10.0, 0.0, 0.0),
            
            # Detailed finger offsets (optimized for sign language precision)
            'LeftHandThumb1': (-1.2, -1.0, 1.8),
            'LeftHandThumb2': (-1.5, -0.3, 1.2),
            'LeftHandThumb3': (-1.3, -0.3, 0.9),
            
            'LeftHandIndex1': (-3.5, 0.8, 1.2),
            'LeftHandIndex2': (-2.5, 0.0, 0.0),
            'LeftHandIndex3': (-2.0, 0.0, 0.0),
            
            'LeftHandMiddle1': (-3.8, 0.6, 0.3),
            'LeftHandMiddle2': (-2.8, 0.0, 0.0),
            'LeftHandMiddle3': (-2.2, 0.0, 0.0),
            
            'LeftHandRing1': (-3.5, 0.3, -0.4),
            'LeftHandRing2': (-2.5, 0.0, 0.0),
            'LeftHandRing3': (-2.0, 0.0, 0.0),
            
            'LeftHandPinky1': (-2.8, 0.1, -1.2),
            'LeftHandPinky2': (-2.0, 0.0, 0.0),
            'LeftHandPinky3': (-1.6, 0.0, 0.0),
            
            # Right hand fingers (mirrored with precision)
            'RightHandThumb1': (1.2, -1.0, 1.8),
            'RightHandThumb2': (1.5, -0.3, 1.2),
            'RightHandThumb3': (1.3, -0.3, 0.9),
            
            'RightHandIndex1': (3.5, 0.8, 1.2),
            'RightHandIndex2': (2.5, 0.0, 0.0),
            'RightHandIndex3': (2.0, 0.0, 0.0),
            
            'RightHandMiddle1': (3.8, 0.6, 0.3),
            'RightHandMiddle2': (2.8, 0.0, 0.0),
            'RightHandMiddle3': (2.2, 0.0, 0.0),
            
            'RightHandRing1': (3.5, 0.3, -0.4),
            'RightHandRing2': (2.5, 0.0, 0.0),
            'RightHandRing3': (2.0, 0.0, 0.0),
            
            'RightHandPinky1': (2.8, 0.1, -1.2),
            'RightHandPinky2': (2.0, 0.0, 0.0),
            'RightHandPinky3': (1.6, 0.0, 0.0),
        }
    
    def _stabilize_torso_reference(self, shoulder_center: Tuple[float, float, float], 
                                  frame_index: int) -> Tuple[float, float, float]:
        """Establish and maintain stable torso reference for sign language"""
        if self.torso_reference is None or frame_index < 10:
            # Initialize or calibrate reference in first few frames
            if frame_index < 10:
                if self.torso_reference is None:
                    self.torso_reference = list(shoulder_center)
                else:
                    # Average the first 10 frames for stable reference
                    for i in range(3):
                        self.torso_reference[i] = (self.torso_reference[i] * frame_index + shoulder_center[i]) / (frame_index + 1)
            return tuple(self.torso_reference)
        
        # Apply strong stabilization for torso
        stabilized = []
        for i in range(3):
            stabilized.append(
                self.torso_reference[i] * self.torso_stability_factor + 
                shoulder_center[i] * (1 - self.torso_stability_factor)
            )
        
        self.torso_reference = stabilized
        return tuple(stabilized)
    
    def _smooth_positions_advanced(self, positions: List[Tuple[float, float, float]]) -> List[Tuple[float, float, float]]:
        """Advanced smoothing specifically for sign language motion"""
        if len(self.position_history) == 0:
            self.position_history.append(positions)
            return positions
        
        self.position_history.append(positions)
        
        if len(self.position_history) < 3:
            return positions
        
        smoothed = []
        for i in range(len(positions)):
            # Different smoothing for different body parts
            if i in [self.pose_landmarks['LEFT_SHOULDER'], self.pose_landmarks['RIGHT_SHOULDER']]:
                # Less smoothing for shoulders to preserve sign language motion
                weight_factor = 0.7
            elif i in [self.pose_landmarks['LEFT_WRIST'], self.pose_landmarks['RIGHT_WRIST'],
                      self.pose_landmarks['LEFT_ELBOW'], self.pose_landmarks['RIGHT_ELBOW']]:
                # Minimal smoothing for hands and elbows (critical for sign language)
                weight_factor = 0.3
            else:
                # Standard smoothing for other parts
                weight_factor = 0.5
            
            x_sum = y_sum = z_sum = weight_sum = 0
            
            for j, frame_positions in enumerate(self.position_history):
                if i < len(frame_positions):
                    # Recent frames get higher weight, but adjusted by body part
                    weight = (j + 1) * weight_factor
                    x_sum += frame_positions[i][0] * weight
                    y_sum += frame_positions[i][1] * weight
                    z_sum += frame_positions[i][2] * weight
                    weight_sum += weight
            
            if weight_sum > 0:
                smoothed.append((x_sum / weight_sum, y_sum / weight_sum, z_sum / weight_sum))
            else:
                smoothed.append(positions[i])
        
        return smoothed
    
    def _mediapipe_to_world_coords(self, landmarks, image_width: int, image_height: int) -> List[Tuple[float, float, float]]:
        """Convert MediaPipe coordinates optimized for sign language"""
        world_coords = []
        scale_factor = 120.0  # Optimized scale for sign language
        
        for landmark in landmarks.landmark:
            # Convert normalized coordinates with proper coordinate system
            x = (landmark.x - 0.5) * image_width * 0.12  # Optimized scaling
            y = (0.5 - landmark.y) * image_height * 0.12  # Flip Y for BVH
            z = landmark.z * scale_factor * 0.08  # Reduced Z sensitivity
            
            world_coords.append((x, y, z))
        
        return world_coords
    
    def _calculate_stable_rotation(self, joint_pos: Tuple[float, float, float], 
                                 child_pos: Tuple[float, float, float],
                                 joint_name: str = "") -> Tuple[float, float, float]:
        """Calculate rotation with stability optimizations for sign language"""
        # Calculate direction vector
        dx = child_pos[0] - joint_pos[0]
        dy = child_pos[1] - joint_pos[1] 
        dz = child_pos[2] - joint_pos[2]
        
        # Calculate length
        length = math.sqrt(dx*dx + dy*dy + dz*dz)
        if length < 1e-6:
            return (0.0, 0.0, 0.0)
        
        # Normalize
        dx /= length
        dy /= length
        dz /= length
        
        # Calculate Euler angles with stability
        x_rot = math.asin(np.clip(dy, -1.0, 1.0))
        y_rot = math.atan2(-dx, dz)
        
        # Minimize Z rotation for stability unless it's a hand joint
        if "Hand" in joint_name:
            z_rot = math.atan2(dx, dy) * 0.3  # Allow some Z rotation for hands
        else:
            z_rot = 0.0
        
        # Convert to degrees and apply smoothing
        rotation = (
            math.degrees(z_rot),
            math.degrees(x_rot), 
            math.degrees(y_rot)
        )
        
        # Apply rotation smoothing
        if len(self.rotation_history) > 0 and joint_name:
            prev_rotation = self.rotation_history[-1].get(joint_name, rotation)
            # Smooth rotation changes
            smoothed_rotation = []
            for i in range(3):
                diff = rotation[i] - prev_rotation[i]
                # Handle angle wrapping
                if diff > 180:
                    diff -= 360
                elif diff < -180:
                    diff += 360
                
                # Apply smoothing based on joint type
                if "Hand" in joint_name or "Finger" in joint_name:
                    smooth_factor = 0.2  # Less smoothing for hands
                else:
                    smooth_factor = 0.4  # More smoothing for body
                
                smoothed_rotation.append(prev_rotation[i] + diff * smooth_factor)
            
            rotation = tuple(smoothed_rotation)
        
        return rotation
    
    def _extract_skeleton_data(self, pose_landmarks, hand_landmarks_list, hand_results, 
                              image_width: int, image_height: int, frame_index: int) -> Dict:
        """Extract skeleton data optimized for sign language"""
        frame_data = {}
        
        if pose_landmarks:
            pose_coords = self._mediapipe_to_world_coords(pose_landmarks, image_width, image_height)
            pose_coords = self._smooth_positions_advanced(pose_coords)
            
            # Get key landmarks
            left_shoulder = pose_coords[self.pose_landmarks['LEFT_SHOULDER']]
            right_shoulder = pose_coords[self.pose_landmarks['RIGHT_SHOULDER']]
            left_elbow = pose_coords[self.pose_landmarks['LEFT_ELBOW']]
            right_elbow = pose_coords[self.pose_landmarks['RIGHT_ELBOW']]
            left_wrist = pose_coords[self.pose_landmarks['LEFT_WRIST']]
            right_wrist = pose_coords[self.pose_landmarks['RIGHT_WRIST']]
            nose = pose_coords[self.pose_landmarks['NOSE']]
            
            # Calculate and stabilize shoulder center
            shoulder_center_raw = (
                (left_shoulder[0] + right_shoulder[0]) / 2,
                (left_shoulder[1] + right_shoulder[1]) / 2,
                (left_shoulder[2] + right_shoulder[2]) / 2
            )
            
            # Apply torso stabilization
            shoulder_center = self._stabilize_torso_reference(shoulder_center_raw, frame_index)
            
            # Stabilized hip position (for sign language, keep torso very stable)
            hip_pos = (
                shoulder_center[0],
                shoulder_center[1] - 25.0,  # Fixed offset below shoulders
                shoulder_center[2]
            )
            
            # Root position - completely stabilized for sign language
            frame_data['Hips'] = [
                hip_pos[0] * 0.05,  # Minimal horizontal movement
                hip_pos[1] * 0.05,  # Minimal vertical movement  
                hip_pos[2] * 0.05,  # Minimal depth movement
                0.0, 0.0, 0.0       # No root rotation
            ]
            
            # Lower body - completely stabilized
            for joint in ['LeftHipJoint', 'LeftUpLeg', 'LeftLeg', 'LeftFoot',
                         'RightHipJoint', 'RightUpLeg', 'RightLeg', 'RightFoot']:
                frame_data[joint] = [0.0, 0.0, 0.0]
            
            # Spine chain - minimal movement, optimized for sign language
            spine_rotation = self._calculate_stable_rotation(hip_pos, shoulder_center, "Spine")
            frame_data['Spine'] = [r * 0.1 for r in spine_rotation]  # Very minimal spine movement
            frame_data['Chest'] = [r * 0.05 for r in spine_rotation]  # Even less chest movement
            
            # Neck and head - allow natural movement but stabilized
            neck_rotation = self._calculate_stable_rotation(shoulder_center, nose, "Neck")
            frame_data['Neck'] = [r * 0.6 for r in neck_rotation]
            frame_data['Head'] = [r * 0.3 for r in neck_rotation]
            
            # Enhanced arm tracking for sign language
            # Left arm chain
            left_shoulder_rot = self._calculate_stable_rotation(shoulder_center, left_shoulder, "LeftShoulder")
            frame_data['LeftShoulder'] = list(left_shoulder_rot)
            
            left_arm_rot = self._calculate_stable_rotation(left_shoulder, left_elbow, "LeftArm")
            frame_data['LeftArm'] = list(left_arm_rot)
            
            left_forearm_rot = self._calculate_stable_rotation(left_elbow, left_wrist, "LeftForeArm")
            frame_data['LeftForeArm'] = list(left_forearm_rot)
            
            frame_data['LeftHand'] = [0.0, 0.0, 0.0]  # Will be overridden by hand data
            
            # Right arm chain
            right_shoulder_rot = self._calculate_stable_rotation(shoulder_center, right_shoulder, "RightShoulder")
            frame_data['RightShoulder'] = list(right_shoulder_rot)
            
            right_arm_rot = self._calculate_stable_rotation(right_shoulder, right_elbow, "RightArm")
            frame_data['RightArm'] = list(right_arm_rot)
            
            right_forearm_rot = self._calculate_stable_rotation(right_elbow, right_wrist, "RightForeArm")
            frame_data['RightForeArm'] = list(right_forearm_rot)
            
            frame_data['RightHand'] = [0.0, 0.0, 0.0]  # Will be overridden by hand data
        
        # Enhanced hand processing for sign language
        if hand_landmarks_list:
            hand_classifications = hand_results.multi_handedness if hand_results and hand_results.multi_handedness else []
            
            for idx, hand_landmarks in enumerate(hand_landmarks_list):
                # Determine hand side with better accuracy
                if idx < len(hand_classifications):
                    detected_side = hand_classifications[idx].classification[0].label
                    side = 'Right' if detected_side == 'Left' else 'Left'  # MediaPipe flips this
                else:
                    side = 'Left' if idx == 0 else 'Right'
                
                self._process_hand_finger_data(frame_data, hand_landmarks, side, image_width, image_height)
        
        # Store rotation history for smoothing
        current_rotations = {}
        for joint_name, values in frame_data.items():
            if len(values) >= 3:
                current_rotations[joint_name] = tuple(values[-3:])
        
        if len(self.rotation_history) >= 5:
            self.rotation_history.popleft()
        self.rotation_history.append(current_rotations)
        
        return frame_data
    
    def _process_hand_finger_data(self, frame_data: Dict, hand_landmarks, side: str, 
                                 image_width: int, image_height: int):
        """Process detailed hand data optimized for sign language precision"""
        hand_coords = self._mediapipe_to_world_coords(hand_landmarks, image_width, image_height)
        
        # Define finger chains with MediaPipe indices (optimized for sign language)
        finger_chains = {
            'Thumb': [(1, 2), (2, 3), (3, 4)],
            'Index': [(5, 6), (6, 7), (7, 8)], 
            'Middle': [(9, 10), (10, 11), (11, 12)],
            'Ring': [(13, 14), (14, 15), (15, 16)],
            'Pinky': [(17, 18), (18, 19), (19, 20)]
        }
        
        # Calculate enhanced hand orientation for sign language
        wrist_pos = hand_coords[0]
        middle_mcp = hand_coords[9]
        index_mcp = hand_coords[5]
        
        # Use multiple reference points for better hand orientation
        palm_center = (
            (middle_mcp[0] + index_mcp[0]) / 2,
            (middle_mcp[1] + index_mcp[1]) / 2,
            (middle_mcp[2] + index_mcp[2]) / 2
        )
        
        hand_rotation = self._calculate_stable_rotation(wrist_pos, palm_center, f"{side}Hand")
        frame_data[f'{side}Hand'] = list(hand_rotation)
        
        # Process each finger with enhanced precision for sign language
        for finger_name, chain in finger_chains.items():
            for i, (parent_idx, child_idx) in enumerate(chain):
                joint_name = f'{side}Hand{finger_name}{i+1}'
                
                if parent_idx < len(hand_coords) and child_idx < len(hand_coords):
                    parent_pos = hand_coords[parent_idx]
                    child_pos = hand_coords[child_idx]
                    
                    # Enhanced rotation calculation for finger precision
                    rotation = self._calculate_stable_rotation(parent_pos, child_pos, joint_name)
                    
                    # Apply finger-specific adjustments for sign language
                    if finger_name == 'Thumb':
                        # Thumb needs special handling for natural movement
                        rotation = (rotation[0] * 0.8, rotation[1] * 1.2, rotation[2] * 0.9)
                    elif finger_name in ['Index', 'Middle']:
                        # Index and middle fingers are most important for sign language
                        rotation = (rotation[0] * 1.1, rotation[1] * 1.0, rotation[2] * 1.0)
                    
                    frame_data[joint_name] = list(rotation)
                else:
                    frame_data[joint_name] = [0.0, 0.0, 0.0]
    
    def _write_bvh_header(self, file) -> int:
        """Write optimized BVH header for sign language"""
        file.write("HIERARCHY\n")
        total_channels = self._write_joint_hierarchy(file, self.joint_hierarchy, 0)
        return total_channels
    
    def _write_joint_hierarchy(self, file, joints: Dict, depth: int) -> int:
        """Write joint hierarchy recursively"""
        total_channels = 0
        indent = "  " * depth
        
        for joint_name, joint_data in joints.items():
            if depth == 0:
                file.write(f"{indent}ROOT {joint_name}\n")
            else:
                file.write(f"{indent}JOINT {joint_name}\n")
            
            file.write(f"{indent}{{\n")
            
            # Write offset
            offset = self.joint_offsets.get(joint_name, (0.0, 0.0, 0.0))
            file.write(f"{indent}  OFFSET {offset[0]:.6f} {offset[1]:.6f} {offset[2]:.6f}\n")
            
            # Write channels
            channels = joint_data['channels']
            total_channels += len(channels)
            channels_str = " ".join(channels)
            file.write(f"{indent}  CHANNELS {len(channels)} {channels_str}\n")
            
            # Process children
            if joint_data['children']:
                child_channels = self._write_joint_hierarchy(file, joint_data['children'], depth + 1)
                total_channels += child_channels
            else:
                file.write(f"{indent}  End Site\n")
                file.write(f"{indent}  {{\n")
                file.write(f"{indent}    OFFSET 0.000000 0.000000 0.000000\n")
                file.write(f"{indent}  }}\n")
            
            file.write(f"{indent}}}\n")
        
        return total_channels
    
    def _collect_frame_values(self, frame_data: Dict, joints: Dict) -> List[float]:
        """Collect frame values in correct BVH order"""
        values = []
        
        for joint_name, joint_info in joints.items():
            if joint_name in frame_data:
                values.extend(frame_data[joint_name])
            else:
                # Fill with default values
                num_channels = len(joint_info['channels'])
                if joint_name == 'Hips':
                    values.extend([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])  # Position + rotation
                else:
                    values.extend([0.0] * num_channels)  # Default rotations
            
            # Recursively collect children values
            if joint_info['children']:
                child_values = self._collect_frame_values(frame_data, joint_info['children'])
                values.extend(child_values)
        
        return values
    
    def process_video(self, video_path: str, output_path: str):
        """Process video with optimized sign language skeleton"""
        print(f"Processing sign language video: {video_path}")
        print("Creating stabilized skeleton optimized for sign language capture...")
        
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Cannot open video file: {video_path}")
        
        # Get video properties
        self.fps = int(cap.get(cv2.CAP_PROP_FPS))
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        image_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        image_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        print(f"Video properties: {image_width}x{image_height}, {self.fps} FPS, {total_frames} frames")
        print("Stabilizing torso, enhancing arm and hand motion capture...")
        
        frame_count = 0
        self.frame_data = []
        self.position_history.clear()
        self.rotation_history.clear()
        self.torso_reference = None
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            # Convert BGR to RGB
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Process with MediaPipe
            pose_results = self.pose.process(rgb_frame)
            hand_results = self.hands.process(rgb_frame)
            
            # Extract skeleton data with frame index for stabilization
            hand_landmarks_list = hand_results.multi_hand_landmarks if hand_results.multi_hand_landmarks else []
            frame_data = self._extract_skeleton_data(
                pose_results.pose_landmarks,
                hand_landmarks_list,
                hand_results,
                image_width,
                image_height,
                frame_count
            )
            
            self.frame_data.append(frame_data)
            frame_count += 1
            
            # Progress reporting with landmark detection info
            if frame_count % 30 == 0:
                progress = (frame_count / total_frames) * 100
                landmarks_detected = 0
                if pose_results.pose_landmarks:
                    landmarks_detected += 33
                landmarks_detected += len(hand_landmarks_list) * 21
                print(f"Processed {frame_count}/{total_frames} frames ({progress:.1f}%) - "
                      f"Detected {landmarks_detected} landmarks - "
                      f"Hands: {len(hand_landmarks_list)}")
        
        cap.release()
        print(f"Finished processing {frame_count} frames")
        
        # Write BVH file
        self._write_bvh_file(output_path)
        print(f"Sign language optimized BVH saved: {output_path}")
        
        # Print optimization info
        total_joints = self._count_total_joints()
        print(f"Generated skeleton with {total_joints} joints:")
        print("• Stabilized torso and lower body")
        print("• Enhanced upper body motion capture")  
        print("• Precise hand and finger tracking")
        print("• Optimized for sign language recognition")
        print("• Professional BVH format compatible")
    
    def _count_total_joints(self) -> int:
        """Count total joints in skeleton"""
        def count_joints(joints_dict):
            count = 0
            for joint_name, joint_data in joints_dict.items():
                count += 1
                if joint_data['children']:
                    count += count_joints(joint_data['children'])
            return count
        
        return count_joints(self.joint_hierarchy)
    
    def _write_bvh_file(self, output_path: str):
        """Write optimized BVH file for sign language"""
        with open(output_path, 'w') as file:
            # Write header
            total_channels = self._write_bvh_header(file)
            
            # Write motion section
            file.write("MOTION\n")
            file.write(f"Frames: {len(self.frame_data)}\n")
            file.write(f"Frame Time: {1.0/self.fps:.6f}\n")
            
            # Write frame data with validation
            for i, frame_data in enumerate(self.frame_data):
                values = self._collect_frame_values(frame_data, self.joint_hierarchy)
                
                # Ensure correct number of channels
                while len(values) < total_channels:
                    values.append(0.0)
                
                # Validate values (no NaN or infinite values)
                validated_values = []
                for v in values[:total_channels]:
                    if math.isnan(v) or math.isinf(v):
                        validated_values.append(0.0)
                    else:
                        validated_values.append(v)
                
                # Write with high precision
                values_str = " ".join(f"{v:.6f}" for v in validated_values)
                file.write(f"{values_str}\n")
                
                # Progress for large files
                if (i + 1) % 100 == 0:
                    print(f"Written {i + 1}/{len(self.frame_data)} frames to BVH")

def main():
    parser = argparse.ArgumentParser(
        description="Convert MP4 to sign language optimized BVH with stable skeleton"
    )
    parser.add_argument("input_video", help="Input MP4 video file path")
    parser.add_argument("-o", "--output", help="Output BVH file path", default=None)
    parser.add_argument("--torso-stability", type=float, default=0.95, 
                       help="Torso stability factor (0.9-0.99, default: 0.95)")
    parser.add_argument("--shoulder-stability", type=float, default=0.8,
                       help="Shoulder stability factor (0.7-0.9, default: 0.8)")
    
    args = parser.parse_args()
    
    # Validate input
    if not os.path.exists(args.input_video):
        print(f"Error: Input video file '{args.input_video}' not found")
        return
    
    # Generate output filename
    if args.output is None:
        base_name = os.path.splitext(os.path.basename(args.input_video))[0]
        args.output = f"{base_name}_sign_language.bvh"
    
    try:
        print("="*80)
        print("SIGN LANGUAGE OPTIMIZED BVH GENERATOR")
        print("="*80)
        print("Features:")
        print("✓ Stabilized torso and lower body (eliminates tilting)")
        print("✓ Enhanced upper body motion capture")
        print("✓ Precise hand and finger tracking for sign language")
        print("✓ Advanced smoothing with motion preservation")
        print("✓ 33 pose landmarks + 42 hand landmarks")
        print("✓ Optimized for cropped videos (head to waist)")
        print("="*80)
        
        generator = SignLanguageBVHGenerator()
        generator.torso_stability_factor = args.torso_stability
        generator.shoulder_stability_factor = args.shoulder_stability
        generator.process_video(args.input_video, args.output)
        
        print("="*80)
        print("SUCCESS! SIGN LANGUAGE BVH GENERATED!")
        print(f"Output file: {args.output}")
        print("Key improvements:")
        print("• Eliminated upper body tilting issue")
        print("• Stabilized torso for consistent standing pose")
        print("• Enhanced hand motion precision")
        print("• Ready for sign language analysis")
        print("="*80)
        
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()