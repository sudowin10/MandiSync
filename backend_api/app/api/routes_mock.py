from fastapi import APIRouter

router = APIRouter(prefix="/api/v1", tags=["Mock & Scaffold"])

@router.post("/register")
async def mock_register():
    return {"status": "success", "message": "User registered"}

@router.get("/stats")
async def mock_stats():
    return {"total_sales": 15000, "active_orders": 4}

@router.get("/transactions")
@router.get("/history")
async def mock_history():
    return {"data": []}

@router.post("/auth/aadhaar/start")
@router.post("/auth/digilocker/start")
async def mock_kyc_start():
    return {"status": "otp_sent", "reference_id": "mock_123"}
