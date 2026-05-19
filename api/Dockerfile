# Use a lightweight Python image
FROM python:3.11-alpine 
# Set the working directory inside the container
WORKDIR /app 
# Install system dependencies needed for Postgres/building tools 
RUN apk add --no-cache gcc musl-dev postgresql-dev 
# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application code
COPY . .

# Expose the Flask port (matching your values.yaml containerPort)
EXPOSE 5000

# Run the Flask application
CMD ["python", "app.py"]