import asyncio
from datetime import date, timedelta
import math
import random
from typing import List, Dict, Any
from motor.motor_asyncio import AsyncIOMotorClient

# Predefined realistic Mandi and Commodity profiles based on actual Agmarknet patterns
MARKET_PROFILES = [
    {
        "state": "Maharashtra",
        "district": "Nashik",
        "market": "Lasalgaon",
        "commodity": "Onion",
        "variety": "Red Onion",
        "base_price": 2200.0,
        "volatility": 0.18,
        "base_arrivals": 1200.0,
        "season_peak_month": 9  # Sept/Oct spike
    },
    {
        "state": "Maharashtra",
        "district": "Nashik",
        "market": "Pimpalgaon",
        "commodity": "Tomato",
        "variety": "Hybrid Tomato",
        "base_price": 1800.0,
        "volatility": 0.28,
        "base_arrivals": 850.0,
        "season_peak_month": 7  # Monsoon spike
    },
    {
        "state": "NCT of Delhi",
        "district": "North Delhi",
        "market": "Azadpur",
        "commodity": "Potato",
        "variety": "Jyoti",
        "base_price": 1400.0,
        "volatility": 0.12,
        "base_arrivals": 2100.0,
        "season_peak_month": 11
    },
    {
        "state": "Madhya Pradesh",
        "district": "Indore",
        "market": "Indore",
        "commodity": "Soybean",
        "variety": "Yellow",
        "base_price": 4600.0,
        "volatility": 0.08,
        "base_arrivals": 950.0,
        "season_peak_month": 10
    },
    {
        "state": "Punjab",
        "district": "Ludhiana",
        "market": "Khanna",
        "commodity": "Wheat",
        "variety": "Sharbati",
        "base_price": 2275.0,  # Near MSP
        "volatility": 0.06,
        "base_arrivals": 1800.0,
        "season_peak_month": 4  # Baisakhi harvest
    },
    {
        "state": "Karnataka",
        "district": "Kolar",
        "market": "Kolar",
        "commodity": "Tomato",
        "variety": "Local",
        "base_price": 1650.0,
        "volatility": 0.25,
        "base_arrivals": 1400.0,
        "season_peak_month": 8
    }
]

def generate_agmarknet_dataset(days_back: int = 365) -> List[Dict[str, Any]]:
    """
    Generate realistic, time-continuous daily Agmarknet price records
    incorporating trend, seasonality, weekend market drops, and realistic price spreads.
    """
    random.seed(42)
    records = []
    end_date = date.today()
    start_date = end_date - timedelta(days=days_back)

    for profile in MARKET_PROFILES:
        current_date = start_date
        current_price = profile["base_price"]

        while current_date <= end_date:
            # Skip Sunday APMC holidays
            if current_date.weekday() != 6:
                day_of_year = current_date.timetuple().tm_yday
                month = current_date.month

                # Seasonality cycle (sine curve peaking at peak month)
                season_factor = 1.0 + 0.25 * math.sin(
                    2 * math.pi * (month - profile["season_peak_month"] + 3) / 12
                )
                
                # Daily random walk with mean reversion to seasonal base
                noise = random.gauss(0, profile["volatility"] * 0.05)
                target = profile["base_price"] * season_factor
                current_price = current_price * 0.95 + target * 0.05 + (target * noise)
                current_price = max(profile["base_price"] * 0.5, current_price)

                # Mandi modal, min, and max spreads
                modal_price = round(current_price, 2)
                spread_pct = random.uniform(0.08, 0.16)
                min_price = round(modal_price * (1.0 - spread_pct * 0.6), 2)
                max_price = round(modal_price * (1.0 + spread_pct * 0.8), 2)

                # Arrivals inversely correlated to price spike
                arrival_noise = random.uniform(0.7, 1.3)
                arrival_tonnes = round(
                    profile["base_arrivals"] * (2.0 - season_factor * 0.5) * arrival_noise, 1
                )

                records.append({
                    "state": profile["state"],
                    "district": profile["district"],
                    "market": profile["market"],
                    "commodity": profile["commodity"],
                    "variety": profile["variety"],
                    "arrival_date": current_date.isoformat(),
                    "min_price": min_price,
                    "max_price": max_price,
                    "modal_price": modal_price,
                    "arrival_tonnes": arrival_tonnes
                })

            current_date += timedelta(days=1)

    return records


async def seed_mongodb(mongo_uri: str = "mongodb://localhost:27017", db_name: str = "mandisync_db"):
    """Seed MongoDB market_prices collection with generated historical Agmarknet records."""
    records = generate_agmarknet_dataset(days_back=365)
    print(f"Generated {len(records)} historical Agmarknet market price records.")
    
    try:
        client = AsyncIOMotorClient(mongo_uri, serverSelectionTimeoutMS=2000)
        await client.admin.command("ping")
        db = client[db_name]
        collection = db["market_prices"]
        
        # Clear existing and insert
        await collection.delete_many({})
        result = await collection.insert_many(records)
        print(f"Successfully seeded {len(result.inserted_ids)} records into MongoDB '{db_name}.market_prices'.")
        client.close()
        return True
    except Exception as exc:
        print(f"MongoDB connection notice: {exc}. (Offline dataset ready for ML ingestion).")
        return False


if __name__ == "__main__":
    asyncio.run(seed_mongodb())
