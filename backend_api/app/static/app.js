/**
 * MandiSync AI Frontend Client
 * Interacts with FastAPI backend routes and Atlas MongoDB
 */

const API_BASE = window.location.origin.includes("localhost") || window.location.origin.includes("127.0.0.1") 
  ? window.location.origin 
  : "http://localhost:8000";

let chartInstance = null;

// Initialize when DOM loads
document.addEventListener("DOMContentLoaded", () => {
  initTabs();
  initChart();
  initPrediction();
  loadLiveMarketPrices();
  loadCropsCatalog();
  loadLogisticsFleet();
  initQuoteCalculator();
  initMockTests();
  checkHealth();
});

// 1. Health Status Ping
async function checkHealth() {
  try {
    const res = await fetch(`${API_BASE}/health`);
    const data = await res.json();
    const statusText = document.getElementById("status-db-text");
    if (data.database === "connected") {
      statusText.innerText = `Atlas Connected • ML Model ${data.ml_model}`;
    }
  } catch (err) {
    console.warn("Health check error:", err);
  }
}

// 2. Tab Navigation
function initTabs() {
  const btns = document.querySelectorAll(".nav-btn");
  btns.forEach(btn => {
    btn.addEventListener("click", () => {
      btns.forEach(b => b.classList.remove("active"));
      document.querySelectorAll(".tab-pane").forEach(p => p.classList.remove("active"));
      
      btn.classList.add("active");
      const tabId = btn.getAttribute("data-tab");
      document.getElementById(tabId).classList.add("active");

      if (tabId === "tab-predict" && chartInstance) {
        chartInstance.resize();
      }
    });
  });
}

// 3. Chart.js Initialization (fl_chart equivalent)
function initChart() {
  const ctx = document.getElementById("forecastChart").getContext("2d");
  
  const gradient = ctx.createLinearGradient(0, 0, 0, 280);
  gradient.addColorStop(0, "rgba(0, 230, 153, 0.35)");
  gradient.addColorStop(1, "rgba(0, 230, 153, 0.0)");

  chartInstance = new Chart(ctx, {
    type: "line",
    data: {
      labels: ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"],
      datasets: [
        {
          label: "Predicted Modal Price (₹/Qtl)",
          data: [2521, 2662, 2843, 2849, 2846, 2846, 2846],
          borderColor: "#00e699",
          borderWidth: 3,
          backgroundColor: gradient,
          fill: true,
          tension: 0.35,
          pointBackgroundColor: "#00e699",
          pointBorderColor: "#fff",
          pointRadius: 5,
          pointHoverRadius: 7
        },
        {
          label: "Upper Confidence (₹)",
          data: [3600, 3741, 3923, 3928, 3925, 3925, 3925],
          borderColor: "rgba(0, 210, 255, 0.4)",
          borderDash: [5, 5],
          borderWidth: 1.5,
          fill: false,
          pointRadius: 0
        },
        {
          label: "Suggested Minimum Floor (₹)",
          data: [2319, 2449, 2616, 2621, 2618, 2618, 2618],
          borderColor: "rgba(255, 183, 3, 0.6)",
          borderWidth: 2,
          fill: false,
          pointRadius: 3
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          labels: { color: "#8e9bb0", font: { family: "Inter", size: 11 } }
        },
        tooltip: {
          backgroundColor: "rgba(10, 14, 23, 0.9)",
          titleFont: { family: "Outfit", size: 13 },
          bodyFont: { family: "Inter", size: 12 },
          borderColor: "rgba(0, 230, 153, 0.3)",
          borderWidth: 1,
          padding: 10
        }
      },
      scales: {
        x: {
          grid: { color: "rgba(255, 255, 255, 0.05)" },
          ticks: { color: "#8e9bb0", font: { family: "Inter" } }
        },
        y: {
          grid: { color: "rgba(255, 255, 255, 0.05)" },
          ticks: {
            color: "#8e9bb0",
            font: { family: "Inter" },
            callback: value => "₹" + value
          }
        }
      }
    }
  });
}

// 4. Run AI Forecast against /api/v1/predict/forecast
function initPrediction() {
  const form = document.getElementById("predict-form");
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = document.getElementById("btn-run-inference");
    btn.innerHTML = `<span>⏳ Computing XGBoost Inference...</span>`;
    
    const commodity = document.getElementById("p-commodity").value;
    const market = document.getElementById("p-market").value;
    const modal_price = document.getElementById("p-modal").value;
    const arrivals = document.getElementById("p-arrivals").value;
    const days = document.getElementById("p-days").value;

    try {
      const url = `${API_BASE}/api/v1/predict/forecast?commodity=${encodeURIComponent(commodity)}&market=${encodeURIComponent(market)}&modal_price=${modal_price}&arrivals=${arrivals}&days=${days}`;
      const res = await fetch(url);
      const data = await res.json();

      if (res.ok && data.forecast) {
        updateForecastUI(data);
      } else {
        alert("Forecast inference returned error: " + (data.detail || "Unknown error"));
      }
    } catch (err) {
      console.error("Forecast fetch error:", err);
      alert("Failed to reach FastAPI backend: " + err.message);
    } finally {
      btn.innerHTML = `<span>⚡ Generate 7-Day Forecast</span>`;
    }
  });
}

function updateForecastUI(data) {
  const points = data.forecast;
  const labels = points.map(p => p.day_name + " (" + p.date.slice(5) + ")");
  const predicted = points.map(p => p.predicted_price);
  const uppers = points.map(p => p.confidence_high);
  const floors = points.map(p => p.recommended_listing_price);

  chartInstance.data.labels = labels;
  chartInstance.data.datasets[0].data = predicted;
  chartInstance.data.datasets[1].data = uppers;
  chartInstance.data.datasets[2].data = floors;
  chartInstance.update();

  if (points.length > 0) {
    document.getElementById("stat-d1").innerText = `₹${points[0].predicted_price.toFixed(0)}`;
    document.getElementById("stat-rec").innerText = `₹${points[0].recommended_listing_price.toFixed(0)}`;
    const spread = (points[0].confidence_high - points[0].predicted_price).toFixed(0);
    document.getElementById("stat-ci").innerText = `± ₹${spread}`;
    document.getElementById("chart-sub").innerText = `${data.commodity} @ ${data.market} (${points.length} Days Horizon)`;
  }
}

// 5. Live Agmarknet Mandi Prices
async function loadLiveMarketPrices() {
  const tbody = document.getElementById("market-table-body");
  const searchInput = document.getElementById("market-search").value.trim();
  
  try {
    let url = `${API_BASE}/api/v1/market-prices?limit=50`;
    if (searchInput) {
      url += `&crop_name=${encodeURIComponent(searchInput)}`;
    }
    const res = await fetch(url);
    const records = await res.json();

    if (res.ok && Array.isArray(records) && records.length > 0) {
      tbody.innerHTML = records.map(r => `
        <tr>
          <td><strong>${r.commodity || "—"}</strong></td>
          <td><span class="badge-pill">${r.variety || "Standard"}</span></td>
          <td>${r.market || "—"}</td>
          <td>${r.state || "—"}</td>
          <td>₹${r.min_price || "—"}</td>
          <td>₹${r.max_price || "—"}</td>
          <td class="text-success"><strong>₹${r.modal_price || "—"}</strong></td>
          <td>${r.arrival_tonnes || r.arrival_volume || "—"}</td>
          <td style="color: var(--text-muted); font-size: 0.8rem">${r.arrival_date || r.date || "—"}</td>
        </tr>
      `).join("");
    } else {
      tbody.innerHTML = `<tr><td colspan="9" class="text-center py-4">No records matching query found.</td></tr>`;
    }
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="9" class="text-center py-4 text-warning">Error loading live data from MongoDB Atlas: ${err.message}</td></tr>`;
  }
}

document.getElementById("btn-refresh-market").addEventListener("click", loadLiveMarketPrices);
document.getElementById("market-search").addEventListener("keyup", (e) => {
  if (e.key === "Enter") loadLiveMarketPrices();
});

// 6. Crop Catalog
async function loadCropsCatalog() {
  const container = document.getElementById("crops-grid");
  try {
    const res = await fetch(`${API_BASE}/api/v1/crops/?limit=20`);
    const crops = await res.json();

    if (res.ok && Array.isArray(crops)) {
      container.innerHTML = crops.map(c => `
        <div class="crop-card">
          <div class="crop-card-header">
            <span class="crop-card-name">${c.name || c.crop_name || "Crop"}</span>
            <span class="badge-pill">${c.category || "General"}</span>
          </div>
          <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 0.75rem;">
            Shelf Life: <strong>${c.shelf_life_days || 14} days</strong> • Grade: <strong>${c.standard_grade || "Grade A"}</strong>
          </p>
          <div style="font-size: 1.1rem; color: var(--primary); font-weight: 700;">
            Govt MSP: ${c.msp ? `₹${c.msp} / Qtl` : 'Market Driven'}
          </div>
        </div>
      `).join("");
    }
  } catch (err) {
    console.error("Crops catalog error:", err);
  }
}
document.getElementById("btn-refresh-crops").addEventListener("click", loadCropsCatalog);

// 7. Logistics Fleet & Quote Calculator
async function loadLogisticsFleet() {
  const container = document.getElementById("providers-list");
  try {
    const res = await fetch(`${API_BASE}/api/v1/logistics/providers?limit=15`);
    const providers = await res.json();

    if (res.ok && Array.isArray(providers)) {
      container.innerHTML = providers.map(p => {
        const isBackhaul = p.status === "RETURNING_EMPTY";
        const badgeClass = isBackhaul ? "provider-badge-empty" : "provider-badge-avail";
        return `
          <div class="provider-card">
            <div>
              <div style="font-weight: 700; color: #fff;">${p.name || p.provider_name || p.id}</div>
              <div style="font-size: 0.8rem; color: var(--text-muted);">
                Base: ${p.home_base || p.current_location || "Mandi Hub"} • Rate: ₹${p.per_km_rate_inr || 22}/km
              </div>
            </div>
            <span class="${badgeClass}">${isBackhaul ? "⚡ Backhaul Available" : p.status}</span>
          </div>
        `;
      }).join("");
    }
  } catch (err) {
    console.error("Logistics fleet error:", err);
  }
}

function initQuoteCalculator() {
  const form = document.getElementById("quote-form");
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const resultBox = document.getElementById("quote-result-box");
    resultBox.classList.remove("hidden");
    resultBox.innerHTML = `<span>Calculating quote & scanning backhauls...</span>`;

    const payload = {
      origin: document.getElementById("q-origin").value,
      destination: document.getElementById("q-dest").value,
      weight_kg: parseFloat(document.getElementById("q-weight").value),
      distance_km: parseFloat(document.getElementById("q-dist").value),
      crop_type: document.getElementById("q-crop").value
    };

    try {
      const res = await fetch(`${API_BASE}/api/v1/logistics/quotes`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });
      const data = await res.json();

      if (res.ok) {
        resultBox.innerHTML = `
          <div style="font-weight: 800; font-size: 1.2rem; color: var(--primary); margin-bottom: 0.5rem;">
            Estimated Cost: ₹${data.estimated_cost_inr}
          </div>
          <div style="font-size: 0.88rem; color: #fff; margin-bottom: 0.25rem;">
            Backhaul Discount Applied: <strong>${data.is_backhaul_discount ? "✅ YES (Save 20-40%)" : "❌ Standard Rate"}</strong>
          </div>
          <div style="font-size: 0.8rem; color: var(--text-muted);">
            Estimated Transit Time: ~${data.estimated_transit_hours || "3-4"} hours
          </div>
        `;
      } else {
        resultBox.innerHTML = `<span style="color: var(--accent-red)">Error: ${JSON.stringify(data)}</span>`;
      }
    } catch (err) {
      resultBox.innerHTML = `<span style="color: var(--accent-red)">Network error: ${err.message}</span>`;
    }
  });
}

// 8. Scaffold / KYC Tests
function initMockTests() {
  document.getElementById("btn-test-kyc").addEventListener("click", async () => {
    const box = document.getElementById("kyc-response");
    box.classList.remove("hidden");
    box.innerText = "Sending OTP request...";
    const res = await fetch(`${API_BASE}/api/v1/auth/aadhaar/start`, { method: "POST" });
    const data = await res.json();
    box.innerText = JSON.stringify(data, null, 2);
  });

  document.getElementById("btn-test-stats").addEventListener("click", async () => {
    const box = document.getElementById("stats-response");
    box.innerText = "Fetching stats...";
    const res = await fetch(`${API_BASE}/api/v1/stats`);
    const data = await res.json();
    box.innerText = JSON.stringify(data, null, 2);
  });
}
