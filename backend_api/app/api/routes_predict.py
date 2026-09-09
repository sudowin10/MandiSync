from datetime import date
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, status
from backend_api.app.models.schemas import PredictionRequest, PredictionResponse
from backend_api.app.services.ml_runner import ml_runner

router = APIRouter(prefix="", tags=["AI Price Prediction Engine"])


@router.get(
    "/predict",
    response_model=PredictionResponse,
    summary="Predict Mandi Maximum Peak Price (GET)",
    description=(
        "Returns dynamic time-series XGBoost maximum price forecasts for agricultural crops in Indian Mandis. "
        "Supports query parameters for seamless browser and IoT agent integration."
    )
)
async def predict_price_get(
    commodity: str = Query(..., description="Crop name e.g. Onion, Tomato, Potato, Wheat, Soybean", examples=["Onion"]),
    market: str = Query(..., description="Target APMC Mandi name e.g. Lasalgaon, Azadpur, Indore, Pimpalgaon", examples=["Lasalgaon"]),
    target_date: Optional[date] = Query(None, alias="date", description="Forecast target date (YYYY-MM-DD)"),
    modal_price: Optional[float] = Query(None, gt=0, description="Latest known modal price (INR / Quintal)", examples=[2450.0]),
    min_price: Optional[float] = Query(None, gt=0, description="Latest known minimum price (INR / Quintal)", examples=[2100.0]),
    arrivals: Optional[float] = Query(None, ge=0, description="Daily arrival quantity in tonnes", examples=[1150.0]),
    variety: str = Query("Standard", description="Variety specification e.g. Garva, Red, Hybrid")
):
    if not ml_runner.is_ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Machine learning model is still initializing or unavailable."
        )

    try:
        prediction = ml_runner.predict(
            commodity=commodity,
            market=market,
            target_date=target_date,
            modal_price_lag1=modal_price,
            min_price_lag1=min_price,
            arrival_tonnes=arrivals,
            variety=variety
        )
        return prediction
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Inference computation error: {str(exc)}"
        )


@router.get(
    "/predict/price",
    response_model=PredictionResponse,
    include_in_schema=False
)
async def predict_price_alias(
    commodity: str = Query(..., description="Crop name"),
    market: str = Query(..., description="Mandi name"),
    date: Optional[date] = Query(None, description="Forecast target date"),
    modal_price: Optional[float] = Query(None, gt=0),
    min_price: Optional[float] = Query(None, gt=0),
    arrivals: Optional[float] = Query(None, ge=0),
    arrival_volume: Optional[float] = Query(None, ge=0),
    variety: str = Query("Standard")
):
    """Alias for /predict endpoint for frontend compatibility."""
    vol = arrivals if arrivals is not None else arrival_volume
    return await predict_price_get(
        commodity=commodity,
        market=market,
        target_date=date,
        modal_price=modal_price,
        min_price=min_price,
        arrivals=vol,
        variety=variety
    )


@router.get(
    "/predict/forecast",
    summary="Get 7-Day Time Series Price Forecast (for Flutter fl_chart)",
    description="Generates consecutive daily price predictions for smooth rendering in chart libraries like Flutter fl_chart."
)
async def predict_forecast_series(
    commodity: str = Query(..., description="Crop name e.g. Onion, Wheat"),
    market: str = Query(..., description="Mandi name e.g. Lasalgaon, Indore"),
    days: int = Query(7, ge=1, le=30, description="Number of future forecast days"),
    modal_price: Optional[float] = Query(None, gt=0, description="Base modal price"),
    min_price: Optional[float] = Query(None, gt=0, description="Base min price"),
    arrivals: Optional[float] = Query(None, ge=0, description="Base arrivals in tonnes"),
    variety: str = Query("Standard")
):
    if not ml_runner.is_ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Machine learning model is still initializing or unavailable."
        )

    from datetime import timedelta
    today = date.today()
    forecast_points = []
    curr_modal = modal_price or 2400.0

    for i in range(days):
        fc_date = today + timedelta(days=i)
        pred = ml_runner.predict(
            commodity=commodity,
            market=market,
            target_date=fc_date,
            modal_price_lag1=curr_modal,
            min_price_lag1=min_price,
            arrival_tonnes=arrivals,
            variety=variety
        )
        forecast_points.append({
            "day_index": i,
            "date": fc_date.isoformat(),
            "day_name": fc_date.strftime("%a"),
            "predicted_price": pred.predicted_max_price,
            "confidence_low": pred.confidence_interval_low,
            "confidence_high": pred.confidence_interval_high,
            "recommended_listing_price": pred.recommended_listing_price
        })
        # Use previous prediction as lag for next step autoregression
        curr_modal = pred.predicted_max_price

    return {
        "status": "success",
        "commodity": commodity,
        "market": market,
        "days": days,
        "forecast": forecast_points,
        "model_version": ml_runner.model_version
    }


@router.post(
    "/predict",
    response_model=PredictionResponse,
    summary="Predict Mandi Maximum Peak Price (POST)",
    description="Accepts full JSON specification payload for batch or programmatic prediction queries."
)
async def predict_price_post(payload: PredictionRequest):
    if not ml_runner.is_ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Machine learning model is still initializing or unavailable."
        )

    try:
        prediction = ml_runner.predict(
            commodity=payload.commodity,
            market=payload.market,
            target_date=payload.target_date,
            modal_price_lag1=payload.modal_price_lag1,
            min_price_lag1=payload.min_price_lag1,
            arrival_tonnes=payload.arrival_tonnes
        )
        return prediction
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Inference computation error: {str(exc)}"
        )


