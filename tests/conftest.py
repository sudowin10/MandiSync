import pytest
import sys
from pathlib import Path

# Add project root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from fastapi.testclient import TestClient
from backend_api.app.main import app
from backend_api.app.core.security import create_access_token


@pytest.fixture(scope="session")
def client():
    """Yield an initialized FastAPI TestClient managing the application lifespan."""
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="session")
def farmer_token():
    """Generate a JWT token for the default farmer user."""
    return create_access_token(data={"sub": "farmer_user", "role": "farmer"})


@pytest.fixture(scope="session")
def admin_token():
    """Generate a JWT token for the default admin user."""
    return create_access_token(data={"sub": "mandi_admin", "role": "admin"})


@pytest.fixture(scope="session")
def farmer_headers(farmer_token):
    """Return authorization headers with Bearer token for farmer."""
    return {"Authorization": f"Bearer {farmer_token}"}


@pytest.fixture(scope="session")
def admin_headers(admin_token):
    """Return authorization headers with Bearer token for admin."""
    return {"Authorization": f"Bearer {admin_token}"}
