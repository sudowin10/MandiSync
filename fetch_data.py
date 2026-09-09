import argparse
import asyncio
import json
import sys
from bson import json_util
try:
    from tabulate import tabulate
except ImportError:
    def tabulate(rows, headers=None, **kwargs):
        lines = []
        if headers:
            lines.append(" | ".join(str(h) for h in headers))
            lines.append("-" * max(len(lines[0]), 40))
        for r in rows:
            lines.append(" | ".join(str(c) for c in r))
        return "\n".join(lines)

from backend_api.app.services.database import db_manager

async def fetch_records(collection_name: str, limit: int = 10, commodity: str = None, market: str = None):
    success = await db_manager.connect_to_mongo()
    if not success:
        print("[-] Failed to connect to MongoDB.")
        return

    db = db_manager.get_database()
    collections = await db.list_collection_names()
    print(f"\n[+] Connected to Database: '{db.name}'")
    print(f"[+] Available Collections: {collections}")

    target_collections = [collection_name] if collection_name != "all" else [c for c in collections if not c.startswith("system.")]

    for coll_name in target_collections:
        coll = db_manager.get_collection(coll_name)
        query = {}
        if commodity:
            query["$or"] = [
                {"commodity": {"$regex": commodity, "$options": "i"}},
                {"descriptor.name": {"$regex": commodity, "$options": "i"}}
            ]
        if market:
            query["$or"] = [
                {"market": {"$regex": market, "$options": "i"}},
                {"mandi_info.market_name": {"$regex": market, "$options": "i"}}
            ]

        count = await coll.count_documents(query)
        print(f"\n" + "="*80)
        print(f" COLLECTION: '{coll_name}' | Matching Documents: {count} (Displaying top {min(count, limit)})")
        print("="*80)

        cursor = coll.find(query).sort("_id", -1).limit(limit)
        docs = await cursor.to_list(length=limit)

        if not docs:
            print("  (No documents found matching criteria)")
            continue

        if coll_name == "market_prices":
            table_data = []
            for d in docs:
                table_data.append([
                    str(d.get("_id"))[-8:],
                    d.get("commodity", "-"),
                    d.get("variety", "-"),
                    d.get("market", "-"),
                    d.get("state", "-"),
                    f"Rs {d.get('min_price', 0):.0f}",
                    f"Rs {d.get('modal_price', 0):.0f}",
                    f"Rs {d.get('max_price', 0):.0f}",
                    f"{d.get('arrival_tonnes', 0)} T",
                    d.get("arrival_date", "-")
                ])
            headers = ["ID", "Commodity", "Variety", "Market", "State", "Min", "Modal", "Max", "Arrivals", "Date"]
            print(tabulate(table_data, headers=headers, tablefmt="fancy_grid"))

        elif coll_name in ["crops", "ondc_crop_listings"]:
            table_data = []
            for d in docs:
                desc = d.get("descriptor", {})
                price = d.get("price", {})
                qty = d.get("quantity", {})
                mandi = d.get("mandi_info", {})
                table_data.append([
                    d.get("id", "-"),
                    desc.get("name", "-"),
                    d.get("category", "-"),
                    f"Rs {price.get('value', 0):.0f}/{qty.get('unit', 'QTL')}",
                    f"{qty.get('available_quantity', 0)} {qty.get('unit', '')}",
                    mandi.get("market_name", "-"),
                    f"Rs {d.get('ai_predicted_max_price', 0):.0f}" if d.get('ai_predicted_max_price') else "N/A"
                ])
            headers = ["SKU / ID", "Crop Name", "Category", "Price", "Available Stock", "Mandi Yard", "AI Max Forecast"]
            print(tabulate(table_data, headers=headers, tablefmt="fancy_grid"))

        else:
            for idx, doc in enumerate(docs, 1):
                doc_str = json.dumps(doc, default=json_util.default, indent=2)
                print(f"Document #{idx} (ID: {doc.get('_id')}):")
                print(doc_str)
                print("-" * 40)

    await db_manager.close_mongo_connection()
    print("\n[+] Done.")

def main():
    parser = argparse.ArgumentParser(description="Fetch and inspect documents from MongoDB.")
    parser.add_argument(
        "--collection", "-c",
        default="all",
        help="Collection to query (e.g. market_prices, crops, ondc_crop_listings, or 'all'). Default: 'all'"
    )
    parser.add_argument("--limit", "-n", type=int, default=5, help="Number of records to fetch per collection. Default: 5")
    parser.add_argument("--commodity", help="Filter by commodity/crop name (e.g. Onion, Wheat, Tomato)")
    parser.add_argument("--market", help="Filter by market name (e.g. Lasalgaon, Sehore, Kolar)")

    args = parser.parse_args()
    asyncio.run(fetch_records(
        collection_name=args.collection,
        limit=args.limit,
        commodity=args.commodity,
        market=args.market
    ))

if __name__ == "__main__":
    main()
