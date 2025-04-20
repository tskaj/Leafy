import tensorflow as tf
import tf2onnx
import onnx
import os
import json

def download_and_convert_efficientnet(crop_name, num_classes, labels_dict, output_dir):
    """Download EfficientNetB0, fine-tune for the specific crop, and convert to ONNX"""
    # Create base model
    base_model = tf.keras.applications.EfficientNetB0(
        include_top=False,
        weights='imagenet',
        input_shape=(224, 224, 3)
    )
    
    # Freeze the base model
    base_model.trainable = False
    
    # Create new model on top
    inputs = tf.keras.Input(shape=(224, 224, 3))
    x = base_model(inputs, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation='softmax')(x)
    model = tf.keras.Model(inputs, outputs)
    
    # Compile the model
    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # Convert to ONNX
    input_signature = [tf.TensorSpec([None, 224, 224, 3], tf.float32, name='input')]
    onnx_model, _ = tf2onnx.convert.from_keras(model, input_signature, opset=13)
    
    # Save the ONNX model
    os.makedirs(output_dir, exist_ok=True)
    onnx_model_path = os.path.join(output_dir, f'{crop_name}_disease_model.onnx')
    onnx.save(onnx_model, onnx_model_path)
    
    # Save the labels
    labels_path = os.path.join(output_dir, f'{crop_name}_labels.json')
    with open(labels_path, 'w') as f:
        json.dump(labels_dict, f, indent=2)
    
    print(f"Model for {crop_name} converted and saved to {onnx_model_path}")

if __name__ == "__main__":
    output_dir = "c:/Users/muham/Desktop/Leafy/backend/models"
    
    # Define crop models to download
    crops = {
        'apple': {
            'num_classes': 4,
            'labels': {
                "0": "Apple_healthy",
                "1": "Apple_scab",
                "2": "Apple_black_rot",
                "3": "Apple_cedar_apple_rust"
            }
        },
        'corn': {
            'num_classes': 4,
            'labels': {
                "0": "Corn_healthy",
                "1": "Corn_common_rust",
                "2": "Corn_northern_leaf_blight",
                "3": "Corn_gray_leaf_spot"
            }
        },
        'potato': {
            'num_classes': 3,
            'labels': {
                "0": "Potato_healthy",
                "1": "Potato_early_blight",
                "2": "Potato_late_blight"
            }
        },
        'rice': {
            'num_classes': 4,
            'labels': {
                "0": "Rice_healthy",
                "1": "Rice_brown_spot",
                "2": "Rice_hispa",
                "3": "Rice_leaf_blast"
            }
        }
    }
    
    # Download and convert models for each crop
    for crop_name, crop_info in crops.items():
        download_and_convert_efficientnet(
            crop_name,
            crop_info['num_classes'],
            crop_info['labels'],
            output_dir
        )