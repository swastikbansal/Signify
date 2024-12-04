    
            results = results.pose_landmarks.landmark
            
            features = mp_utils.extract_features(results)
            
            sequence.append(features)