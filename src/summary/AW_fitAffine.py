import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression

# Load your CSV file
df = pd.read_csv('your_file.csv')

# Source coordinates (image_x, image_y)
X = df[['image_x', 'image_y']].values

# Target coordinates (ccf_ap, ccf_ml, ccf_dv)
Y = df[['ccf_ap', 'ccf_ml', 'ccf_dv']].values

# Add a column of ones to X for the affine transform (bias term)
X_aug = np.hstack([X, np.ones((X.shape[0], 1))])

# Fit affine transform for each output dimension
reg = LinearRegression(fit_intercept=False)
reg.fit(X_aug, Y)

# reg.coef_ is a (3, 3) matrix: rows are output dims, columns are [image_x, image_y, bias]
affine_matrix = reg.coef_

print("Affine transformation matrix (rows: [ccf_ap, ccf_ml, ccf_dv]; columns: [image_x, image_y, bias]):")
print(affine_matrix)


df['affine_ccf_ap'] = affine_matrix[0, 0] * df['image_x'] + affine_matrix[0, 1] * df['image_y'] + affine_matrix[0, 2]
df['affine_ccf_ml'] = affine_matrix[1, 0] * df['image_x'] + affine_matrix[1, 1] * df['image_y'] + affine_matrix[1, 2]
df['affine_ccf_dv'] = affine_matrix[2, 0] * df['image_x'] + affine_matrix[2, 1] * df['image_y'] + affine_matrix[2, 2]

# To transform new points:
def transform_image_to_ccf(image_x, image_y):
    pt = np.array([image_x, image_y, 1.0])
    return affine_matrix @ pt

# Example usage:
# new_ccf = transform_image_to_ccf(100, 200)