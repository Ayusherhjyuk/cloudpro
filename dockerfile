FROM python:3.10-slim

WORKDIR /app

# Copy requirements first (for caching layers in Docker)
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/process.py .

# Environment variables (buckets & keys)
ENV RAW_BUCKET=raw-data
ENV PROCESSED_BUCKET=processed-data
ENV INPUT_KEY=input.csv
ENV OUTPUT_KEY=output.csv

CMD ["python", "process.py"]
