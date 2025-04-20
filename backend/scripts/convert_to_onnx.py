import tensorflow as tf
import tf2onnx
import onnx
import os

def convert_h5_to_onnx(h5_model_path, onnx_model_path):
    # Load the H5 model
    model = tf.keras.models.load_model(h5_model_path)
    
    # Convert the model to ONNX
    input_signature = [tf.TensorSpec([None, 224, 224, 3], tf.float32, name='input')]
    onnx_model, _ = tf2onnx.convert.from_keras(model, input_signature, opset=13)
    
    # Save the ONNX model
    onnx.save(onnx_model, onnx_model_path)
    
    print(f"Model converted and saved to {onnx_model_path}")

if __name__ == "__main__":
    # Path to your H5 model
    h5_model_path = "c:/Users/muham/Desktop/Leafy/backend/models/tomato_disease_model.h5"
    
    # Path to save the ONNX model
    onnx_model_path = "c:/Users/muham/Desktop/Leafy/backend/models/tomato_disease_model.onnx"
    
    # Create models directory if it doesn't exist
    os.makedirs(os.path.dirname(onnx_model_path), exist_ok=True)
    
    # Convert the model
    convert_h5_to_onnx(h5_model_path, onnx_model_path)