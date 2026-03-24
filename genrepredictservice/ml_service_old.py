from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
import pandas as pd
from transformers import DistilBertTokenizer, DistilBertModel
import json
import os

# ==========================================
# 1. Setup & Configuration
# ==========================================
app = FastAPI(title="Goodreads Genre Predictor API")
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Define paths (Update these to where you downloaded your Colab files)
MODEL_PATH = "distilbert_genre_model.pth"
INDEX_PATH = "genre_index.json"
THRESHOLDS_PATH = "optimal_thresholds.json"

# ==========================================
# 2. Global State (Load Once at Startup)
# ==========================================
print("Loading Genere Index...")
if not os.path.exists(INDEX_PATH):
    raise RuntimeError(f"Cannot find {INDEX_PATH}! Please download it from Colab.")

# Load genres dynamically!
genres_series = pd.read_json(INDEX_PATH, typ='series')
GENRES_LIST = genres_series.tolist()
print(f"Loaded {len(GENRES_LIST)} genres.")

# Recreate the exact model architecture from Colab
class DistilBertMultiLabel(torch.nn.Module):
    def __init__(self, n_classes):
        super().__init__()
        self.bert = DistilBertModel.from_pretrained("distilbert-base-uncased")
        self.dropout = torch.nn.Dropout(0.3)
        self.classifier = torch.nn.Linear(self.bert.config.hidden_size, n_classes)

    def forward(self, input_ids, attention_mask):
        outputs = self.bert(input_ids=input_ids, attention_mask=attention_mask)
        cls_token = outputs.last_hidden_state[:, 0]
        x = self.dropout(cls_token)
        return self.classifier(x)

print("Loading Model and Tokenizer...")
tokenizer = DistilBertTokenizer.from_pretrained('distilbert-base-uncased')

model = DistilBertMultiLabel(n_classes=len(GENRES_LIST))
model.load_state_dict(torch.load(MODEL_PATH, map_location=device, weights_only=True))
model = model.to(device)
model.eval()

# Load Tuned Thresholds (with safety fallback)
try:
    with open(THRESHOLDS_PATH, 'r') as f:
        thresholds = json.load(f)
    print("Loaded tuned thresholds.")
except FileNotFoundError:
    print(f"Warning: {THRESHOLDS_PATH} not found. Defaulting all thresholds to 0.5")
    thresholds = {genre: 0.5 for genre in GENRES_LIST}

# ==========================================
# 3. API Endpoints
# ==========================================
# Update your request model to accept both!
class BookRequest(BaseModel):
    title: str
    description: str

@app.post("/predict")
async def predict_genre(request: BookRequest):
    if not request.description.strip():
        raise HTTPException(status_code=400, detail="Description cannot be empty.")

    # Combine them exactly like we did during training!
    combined_text = f"{request.title} {request.description}"

    # Tokenize the combined text
    encoding = tokenizer(
        combined_text,
        add_special_tokens=True,
        max_length=256,
        padding='max_length',
        truncation=True,
        return_attention_mask=True,
        return_tensors='pt'
    )

    input_ids = encoding['input_ids'].to(device)
    attention_mask = encoding['attention_mask'].to(device)

    # Run Inference
    with torch.no_grad():
        logits = model(input_ids, attention_mask)
        probs = torch.sigmoid(logits).cpu().numpy()[0]

    # Map probabilities to genres
    predictions = {}

    # Store ALL genres with their probabilities so we can sort them
    all_scored_genres = []

    for i, genre in enumerate(GENRES_LIST):
        prob = float(probs[i])
        threshold = thresholds.get(genre, 0.5)
        is_match = prob >= threshold

        predictions[genre] = {
            "probability": round(prob, 4),
            "threshold": threshold,
            "is_match": is_match
        }
        all_scored_genres.append((genre, prob, is_match))

    # Sort everything from highest probability to lowest
    all_scored_genres.sort(key=lambda x: x[1], reverse=True)

    # 1. Get the ones that actually passed the threshold
    confirmed_genres = [g[0] for g in all_scored_genres if g[2]]

    # 2. Always grab the top 3 highest probabilities (even if they failed the threshold)
    # But don't include them if they are already in the "confirmed" list!
    suggested_genres = []
    for g in all_scored_genres[:3]:
        if not g[2]:  # If it wasn't a confirmed match
            suggested_genres.append(g[0])

    return {
        "predicted_genres": confirmed_genres,
        "suggested_genres": suggested_genres,
        "details": predictions
    }