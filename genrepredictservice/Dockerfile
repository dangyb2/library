FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install torch --index-url https://download.pytorch.org/whl/cpu && \
    pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "ml_service:app", "--host", "0.0.0.0", "--port", "8000"]