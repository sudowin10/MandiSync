# MandiSync Flutter — Smart Agriculture Marketplace & Intelligence

A complete, cross-platform **Flutter** application conversion of MandiSync, powered by Material 3, provider-based state management, and direct integration with the FastAPI backend.

---

## 🚀 Features & Architecture

### 1. 🏛️ Government of India Agriculture Theme
- Official Ministry of Agriculture & Farmers Welfare identity (`GovBar`).
- Real-time backend API status dot (`/health` & `/` monitoring at `10.0.41.4:8000`).

### 2. 🌾 Agmarknet APMC Mandi Prices
- Live commodity market rate feed (`/api/v1/market-prices`).
- Real-time search and filtering by crop, mandi, and state.
- Interactive **Add Mandi Rate** submission modal.

### 3. 📦 ONDC Beckn Crop Marketplace
- Direct farmer harvest listing form (`/api/v1/crops`).
- Standardized open commerce catalog (`/api/v1/ondc/crop_listings`).
- Real-time listing management with delete and status updates.

### 4. 🤖 XGBoost AI Price Analytics
- Machine learning time-series price peak forecasting (`/api/v1/predict`).
- Optimal selling window recommendations and confidence intervals.

### 5. 🚚 Smart Backhaul Logistics & Fleet
- Trip delivery quote calculator with automatic 20–40% freight discounts on empty return legs (`/api/v1/logistics/quotes`).
- Available transporters directory and backhaul cargo matching (`/api/v1/logistics/match-backhauls`).
- New transport vehicle registration (`/api/v1/logistics/providers`).

### 6. 🪪 Aadhaar & DigiLocker Digital Public Infrastructure
- Direct UIDAI Aadhaar 6-digit OTP verification simulation & API flow (`/auth/aadhaar/start`, `/auth/aadhaar/verify`).
- National DigiLocker gateway identity connection (`/auth/digilocker/start`).

### 7. 📊 Dashboard, Transactions & Audit Logs
- Farmer revenue metrics, active orders, and +18.4% price improvement benchmarks (`/stats`).
- Financial settlements & escrow transaction history (`/transactions`).
- Complete activity timeline audit log (`/history`).

---

## 📁 Project Structure

```
mandisync_flutter/
├── pubspec.yaml
├── README.md
└── lib/
    ├── main.dart                   # MultiProvider, Material 3 Theme, Named Routing
    ├── constants/
    │   ├── api_constants.dart      # Base URLs (http://10.0.41.4:8000), endpoints, keys
    │   └── app_theme.dart          # Indian Gov Green, Saffron, Dark Slate palette
    ├── models/
    │   ├── user_model.dart         # UserModel & AuthResponse
    │   ├── crop_model.dart         # CropModel & ONDC item
    │   ├── market_price_model.dart # MarketPriceModel
    │   ├── prediction_model.dart   # PredictionRequest & PredictionResult
    │   ├── logistics_model.dart    # TransportProvider & LogisticsQuote
    │   └── stats_models.dart       # DashboardStats, TransactionItem, HistoryLog
    ├── services/
    │   ├── api_service.dart        # Central HTTP client with Bearer token & error translation
    │   ├── auth_service.dart       # JWT auth, Aadhaar OTP, DigiLocker
    │   ├── crop_service.dart       # Crops CRUD & ONDC catalog
    │   ├── market_service.dart     # Mandi prices fetch & create
    │   ├── analytics_service.dart  # XGBoost AI forecasting
    │   ├── logistics_service.dart  # Quotes, transporters, backhaul matching
    │   └── stats_service.dart      # Stats, transactions, activity logs
    ├── providers/
    │   ├── app_provider.dart       # Health status & global state
    │   ├── auth_provider.dart      # Auth state & user session
    │   ├── market_provider.dart    # Mandi prices & filter state
    │   ├── crop_provider.dart      # Farmer crops & ONDC state
    │   └── logistics_provider.dart # Logistics & backhaul state
    ├── widgets/
    │   ├── gov_bar.dart            # 🇮🇳 Gov of India bar with API pulse
    │   ├── mandi_app_bar.dart      # Top app bar with brand & profile dropdown
    │   ├── app_nav_drawer.dart     # Side drawer navigation
    │   └── aadhaar_otp_dialog.dart # Aadhaar OTP dialog modal
    └── screens/
        ├── home_screen.dart        # Hero, live snapshot ticker, capability cards
        ├── markets_screen.dart     # APMC Mandi, Farmer Crops, ONDC tabs + Add dialog
        ├── crop_listing_screen.dart# Sell crops form + My crop listings
        ├── analytics_screen.dart   # XGBoost prediction form & forecast preview
        ├── logistics_screen.dart   # Quote calculator & fleet transporters
        ├── signin_screen.dart      # Sign in + Aadhaar & DigiLocker
        ├── register_screen.dart    # Citizen registration with roles
        ├── profile_screen.dart     # Profile details edit & deactivation
        ├── stats_screen.dart       # Performance KPI dashboard
        ├── transactions_screen.dart# Settlements & Escrow transactions
        └── history_screen.dart     # Activity audit logs
```

---

## 🛠️ How to Run

1. Make sure Flutter SDK is installed and on your `PATH`.
2. Navigate to this directory:
   ```bash
   cd mandisync_flutter
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run on Chrome (Web), Android, or Windows desktop:
   ```bash
   flutter run -d chrome
   # or
   flutter run -d windows
   ```
