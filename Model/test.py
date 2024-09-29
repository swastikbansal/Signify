def create_model(input_shape, num_classes=50, time_steps=10):  # Added time_steps parameter
    # Input layer
    inputs = Input(shape=(time_steps, *input_shape))  # Adjusted input shape to include time steps
    
    # MobileNetV2 base
    base_model = MobileNetV2(input_shape=input_shape, include_top=False, weights='imagenet')
    base_model.trainable = True  # Freeze the base model
    
    # Apply MobileNetV2 to each time step
    x = TimeDistributed(base_model)(inputs)
    
    # Reshape to 3D tensor for LSTM layers
    shape = tf.keras.backend.int_shape(x)
    x = Reshape((shape[1], -1))(x)
    
    # Bidirectional LSTM layers
    
    x = Bidirectional(LSTM(32, return_sequences=True))(x)
    x = Bidirectional(LSTM(32, return_sequences=True))(x)
    # x = Bidirectional(LSTM(64, return_sequences=True))(x)
    # x = Bidirectional(LSTM(64, return_sequences=True))(x)
    # x = Bidirectional(LSTM(64, return_sequences=True))(x)
    # x = Bidirectional(LSTM(64, return_sequences=True))(x)
    # x = Bidirectional(LSTM(64, return_sequences=True))(x)
    
    # Flatten the output
    x = Flatten()(x)
    
    # Fully connected layer
    x = Dense(128, activation='relu')(x)
    
    # Output layer
    outputs = Dense(num_classes, activation='softmax')(x)
    
    # Create the model
    model = Model(inputs=inputs, outputs=outputs)
    
    return model

from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Input, Dense, LSTM, Bidirectional, Flatten, TimeDistributed, Reshape
from tensorflow.keras.models import Model

tf.keras.backend.clear_session()

if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
    except RuntimeError as e:
        print(e)
