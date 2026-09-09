# MandiSync AI — Smart India Hackathon 2026 🌾

> **AI-Powered Agri-Commerce Platform** — Connecting farmers, mandis, buyers, and transporters through real-time XGBoost price forecasts, Beckn ONDC commerce, and smart backhaul logistics matching.

---

## 🏗️ Architecture Overview

```
MandiSync_SIH26/
├── backend_api/        # FastAPI (27 REST API endpoints)
├── ml_engine/          # XGBoost Time-Series Price Predictor
├── tests/              # 42 Automated test cases (all passing)
├── flutter_sdk/        # Dart models + API services for Flutter UI
├── Dockerfile          # Docker container for backend
├── docker-compose.yml  # Full stack launcher
└── .github/workflows/  # Automated CI pipeline
```

---

## 🚀 Quick Start

### Option 1: Run with Docker (Recommended)
```bash
# Build and start the entire backend stack
docker compose up --build

# Swagger Docs:   http://localhost:8000/docs
# Dashboard:      http://localhost:8000/app
# Health Check:   http://localhost:8000/health
```

### Option 2: Run Locally (Python)
```bash
# 1. Clone the repository
git remote add origin https://github.com/sudowin10/MandiSync.git
cd MandiSync_SIH26

# 2. Create virtual environment
python -m venv .venv
.venv\Scripts\activate   # Windows
source .venv/bin/activate # Mac/Linux

# 3. Install dependencies
pip install -r backend_api/requirements.txt

# 4. Train the ML model (first time only)
python ml_engine/train_xgboost.py

# 5. Start the FastAPI server
python -m uvicorn backend_api.app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Option 3: Run Tests
```bash
python -m pytest tests/ -v
# Expected: 42 passed
```

---

## 🔗 API Endpoints Reference

| Group | Endpoint | Description |
|---|---|---|
| AI Forecast | `GET /api/v1/predict/forecast` | 7-Day XGBoost price time series |
| Market | `GET /api/v1/market-prices` | 305+ live Agmarknet mandi records |
| Crops | `GET /api/v1/crops/` | Crop catalog with MSP |
| Logistics | `POST /api/v1/logistics/quotes` | Smart delivery quote with backhaul matching |
| Auth | `POST /api/v1/auth/login` | JWT token issuance |
| Users | `POST /api/v1/auth/register` | Farmer / Buyer / Trader registration |
| ONDC | `POST /api/v1/ondc/search` | Beckn Protocol discovery webhook |
| Health | `GET /health` | Service & MongoDB Atlas health check |

**Interactive API Docs**: `http://localhost:8000/docs`

---

## 📱 Flutter SDK for Anshul's UI

Copy `flutter_sdk/lib/` into your Flutter project. See [`flutter_sdk/README.md`](flutter_sdk/README.md) for full wiring instructions.

```dart
// One-line setup — works on same Wi-Fi
final api = MandiSyncApiService(baseUrl: 'http://10.0.41.4:8000');

// 7-Day forecast with fl_chart ready FlSpot objects
final forecast = await api.getPriceForecast(commodity: 'Onion', market: 'Lasalgaon');
```

---

## 🧠 ML Engine

- **Model**: XGBoost Regressor trained on **305 real Agmarknet government records**
- **Features**: Time-series lags, rolling averages, calendar signals (day of week, month, seasonality)
- **Accuracy**: R² = 0.95, RMSE = ₹655/Qtl on out-of-time test set
- **Inference Latency**: ~5ms per request

---

## 🗄️ Database — MongoDB Atlas

- **Cluster**: `cluster0.sgu4gdt.mongodb.net` (`mandisync_db`)
- **Collections**: `market_prices`, `crops`, `logistics_providers`, `users`, `harvest_listings`, `ondc_orders`, `price_forecasts`, `alerts_advisories`

---

## 👥 Team

| Name | Role |
|---|---|
| Amritanshu (Team leader) | FastAPI, ML Engine, Backend |
| Abhijeet | Data Engineering, Agmarknet Ingestion , MongoDB Atlas |
| Anshul | Flutter UI |
| Kartikey | Deployment, Git, Docker |
| Thanay | Design |
| Gunjan | Pitching |
---

*MandiSync AI — Smart India Hackathon SIH 2026*
