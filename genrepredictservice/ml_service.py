from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
import pandas as pd
from transformers import DistilBertTokenizer, DistilBertModel
import json
import os

# ==========================================
# 1. Pydantic Models (Request & Response)
# ==========================================
class BookRequest(BaseModel):
    title: str
    description: str

class GenrePrediction(BaseModel):
    genre: str
    confidence: float
    is_match: bool

class PredictionResponse(BaseModel):
    predictions: list[GenrePrediction]

# ==========================================
# 2. PyTorch Model Architecture
# ==========================================
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

# ==========================================
# 3. Application State & Lifespan
# ==========================================
MODEL_PATH = "distilbert_genre_model.pth"
INDEX_PATH = "genre_index.json"
THRESHOLDS_PATH = "optimal_thresholds.json"

# Dictionary to hold our loaded models and data
ml_context = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Initializing Machine Learning Context...")
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    ml_context['device'] = device

    # Load Genres
    if not os.path.exists(INDEX_PATH):
        raise RuntimeError(f"Cannot find {INDEX_PATH}!")
    genres_series = pd.read_json(INDEX_PATH, typ='series')
    ml_context['genres'] = genres_series.tolist()
    
    # Load Thresholds
    try:
        with open(THRESHOLDS_PATH, 'r') as f:
            ml_context['thresholds'] = json.load(f)
    except FileNotFoundError:
        print(f"Warning: {THRESHOLDS_PATH} not found. Defaulting to 0.5")
        ml_context['thresholds'] = {g: 0.5 for g in ml_context['genres']}

    # Load Tokenizer & Model
    print("Loading DistilBERT Tokenizer and Model (this may take a moment)...")
    ml_context['tokenizer'] = DistilBertTokenizer.from_pretrained('distilbert-base-uncased')
    
    model = DistilBertMultiLabel(n_classes=len(ml_context['genres']))
    model.load_state_dict(torch.load(MODEL_PATH, map_location=device, weights_only=True))
    model = model.to(device)
    model.eval()
    ml_context['model'] = model
    
    print("✅ Application is ready to accept traffic.")
    
    yield  # App runs here
    
    # Clean up resources on shutdown
    ml_context.clear()

# ==========================================
# 4. API Endpoints
# ==========================================
app = FastAPI(title="Goodreads Genre Predictor API", lifespan=lifespan)

@app.post("/predict", response_model=PredictionResponse)
async def predict_genre(request: BookRequest):
    if not request.description.strip():
        raise HTTPException(status_code=400, detail="Description cannot be empty.")

    combined_text = f"{request.title} {request.description}"
    device = ml_context['device']

    # Tokenize
    encoding = ml_context['tokenizer'](
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

    # Inference
    with torch.no_grad():
        logits = ml_context['model'](input_ids, attention_mask)
        probs = torch.sigmoid(logits).cpu().numpy()[0]

    # Map predictions
    predictions = []
    for i, genre in enumerate(ml_context['genres']):
        prob = float(probs[i])
        threshold = ml_context['thresholds'].get(genre, 0.5)
        
        predictions.append(
            GenrePrediction(
                genre=genre,
                confidence=round(prob, 4),
                is_match=bool(prob >= threshold)
            )
        )

    # Sort from highest confidence to lowest
    predictions.sort(key=lambda x: x.confidence, reverse=True)

    return PredictionResponse(predictions=predictions)