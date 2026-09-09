import asyncio
import logging
import os
import sys
from pathlib import Path
from typing import Optional
import pandas as pd
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.errors import PyMongoError

# Add repository root to path for cross-imports
CURRENT_DIR = Path(__file__).resolve().parent
REPO_ROOT = CURRENT_DIR.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from ml_engine.seed_market_data import generate_agmarknet_dataset
from backend_api.app.core.config import settings

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("ml_engine.data_ingestion")


async def fetch_agmarknet_data_from_mongo(
    mongo_uri: Optional[str] = None,
    db_name: Optional[str] = None,
    collection_name: str = "market_prices"
) -> pd.DataFrame:
    """
    Asynchronously fetch historical Agmarknet records from MongoDB into a Pandas DataFrame.
    If the collection is empty or MongoDB server is unreachable, automatically falls back
    to generating realistic historical records so the ML pipeline remains self-sufficient.
    """
    uri = mongo_uri or settings.MONGO_URI
    target_db = db_name or settings.MONGO_DB_NAME

    logger.info(f"Connecting to MongoDB at {uri} to fetch collection '{collection_name}'...")
    raw_records = []
    
    try:
        client = AsyncIOMotorClient(uri, serverSelectionTimeoutMS=settings.MONGO_TIMEOUT_MS)
        # Verify connection
        await client.admin.command("ping")
        db = client[target_db]
        collection = db[collection_name]

        cursor = collection.find({}, {"_id": 0})
        raw_records = await cursor.to_list(length=100000)
        client.close()
        logger.info(f"Retrieved {len(raw_records)} documents from MongoDB '{target_db}.{collection_name}'.")
    except (PyMongoError, Exception) as exc:
        logger.warning(f"MongoDB connection notice: {exc}. Using generated historical Agmarknet dataset.")

    # Fallback to high-fidelity historical dataset if collection is empty
    if not raw_records:
        logger.info("Generating realistic historical Agmarknet market price dataset...")
        raw_records = generate_agmarknet_dataset(days_back=365)
        logger.info(f"Loaded {len(raw_records)} records into pipeline.")

    df = pd.DataFrame(raw_records)
    return df


def engineer_timeseries_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Process raw Agmarknet market price records into clean time-series features
    suitable for XGBoost regression predicting max_price.
    """
    if df.empty:
        raise ValueError("Cannot engineer features on an empty DataFrame.")

    # -----------------------------------------------------------------------
    # 1. Sanitize price columns before anything else.
    #    MongoDB documents may have None / string values that become NaN.
    # -----------------------------------------------------------------------
    price_cols = ["min_price", "max_price", "modal_price", "arrival_tonnes"]
    for col in price_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # -----------------------------------------------------------------------
    # 1b. Field name normalization — older seeded docs use 'date' instead of
    #     'arrival_date'. Merge both into a single canonical 'arrival_date' col.
    # -----------------------------------------------------------------------
    if "arrival_date" not in df.columns:
        df["arrival_date"] = None
    if "date" in df.columns:
        # Fill missing arrival_date from 'date' field
        missing_mask = df["arrival_date"].isna()
        df.loc[missing_mask, "arrival_date"] = df.loc[missing_mask, "date"]
        logger.info(f"Normalized 'date' → 'arrival_date' for {missing_mask.sum()} documents.")

    # -----------------------------------------------------------------------
    # 2. Parse arrival_date with coerce — bad/missing dates become NaT
    #    then immediately drop those rows so the temporal split is clean.
    # -----------------------------------------------------------------------
    df["arrival_date"] = pd.to_datetime(df["arrival_date"], errors="coerce")

    before = len(df)
    df = df.dropna(subset=["arrival_date", "max_price"]).reset_index(drop=True)
    dropped = before - len(df)
    if dropped:
        logger.warning(
            f"Dropped {dropped} rows with missing/unparseable arrival_date or max_price "
            f"({before} → {len(df)} rows remaining)."
        )

    if df.empty:
        raise ValueError(
            "No valid training rows remain after dropping missing arrival_date / max_price. "
            "Seed your MongoDB market_prices collection with complete records."
        )

    df = df.sort_values(by=["commodity", "market", "arrival_date"]).reset_index(drop=True)

    # Calendar and cyclical features
    df["day_of_week"] = df["arrival_date"].dt.dayofweek
    df["month"] = df["arrival_date"].dt.month
    df["day_of_year"] = df["arrival_date"].dt.dayofyear

    # Grouped lag features per commodity and market
    grouped = df.groupby(["commodity", "market"])

    # Previous day's modal price and min price (Lag 1)
    df["modal_price_lag1"] = grouped["modal_price"].shift(1)
    df["min_price_lag1"] = grouped["min_price"].shift(1)

    # 7-day rolling window modal price statistics
    df["modal_price_7d_mean"] = grouped["modal_price"].transform(
        lambda s: s.rolling(window=7, min_periods=1).mean()
    )

    # 7-day rolling arrival volume
    df["arrival_tonnes_7d_mean"] = grouped["arrival_tonnes"].transform(
        lambda s: s.rolling(window=7, min_periods=1).mean()
    )

    # Price spread (modal minus min)
    df["price_spread"] = df["modal_price"] - df["min_price"]

    # Impute initial lag NaNs with current values (first row of each group has no lag)
    df["modal_price_lag1"] = df["modal_price_lag1"].fillna(df["modal_price"])
    df["min_price_lag1"] = df["min_price_lag1"].fillna(df["min_price"])
    df["modal_price_7d_mean"] = df["modal_price_7d_mean"].fillna(df["modal_price"])
    df["arrival_tonnes_7d_mean"] = df["arrival_tonnes_7d_mean"].fillna(df["arrival_tonnes"])

    # -----------------------------------------------------------------------
    # 3. Final global sanitization pass — replace inf with NaN and drop.
    #    Rolling calculations on edge rows can produce inf if dividing by 0.
    # -----------------------------------------------------------------------
    df = df.replace([float("inf"), float("-inf")], float("nan"))
    critical_cols = ["max_price", "modal_price_lag1", "min_price_lag1",
                     "modal_price_7d_mean", "price_spread"]
    df = df.dropna(subset=critical_cols).reset_index(drop=True)

    logger.info(f"Feature engineering complete. Total rows: {len(df)}, Columns: {list(df.columns)}")
    return df


async def main():
    df_raw = await fetch_agmarknet_data_from_mongo()
    df_features = engineer_timeseries_features(df_raw)
    print("\n--- Ingested Data Sample (First 5 Rows) ---")
    print(df_features[["arrival_date", "commodity", "market", "min_price", "modal_price", "max_price", "modal_price_lag1", "modal_price_7d_mean"]].head())
    print("\n--- Dataset Summary ---")
    print(df_features.describe())


if __name__ == "__main__":
    asyncio.run(main())
