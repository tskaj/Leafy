from tensorflow.keras.models import load_model

# Load the model
model_path = "backend\models\My_Efficient-B1_acc98.3.h5"
model = load_model(model_path)

# Get input shape and output classes
input_shape = model.input_shape
output_classes = model.output_shape[-1]

# Inspect the model for class labels (if available in metadata)
try:
    class_labels = model.class_names  # Adjust the attribute name based on your model
    print("Class labels:", class_labels)
except AttributeError:
    print("Class labels are not available in the model.")

