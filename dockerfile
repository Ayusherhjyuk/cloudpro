FROM python:3.10-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/process.py .

ENV RAW_BUCKET=raw-data
ENV PROCESSED_BUCKET=processed-data
ENV INPUT_KEY=input.csv
ENV OUTPUT_KEY=output.csv

CMD ["python", "process.py"]
