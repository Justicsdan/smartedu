/* ============================================
   SMARTEDU MAIN JAVASCRIPT
   Handles login, auth, and dashboard UI logic
   ============================================ */

document.addEventListener("DOMContentLoaded", () => {
  initApp();
});

const API_BASE = 'http://localhost:8000/api'; // Match your PHP API URL

// --- 1. Initialization ---
function initApp() {
  handleLogin();
  handleNavbar();
  handleSmoothScroll();
  handleLogout();

  // Load Dashboard Data based on URL
  if (window.location.pathname.includes('admin_dashboard.html')) {
    loadAdminDashboard();
  } else if (window.location.pathname.includes('teacher_dashboard.html')) {
    loadTeacherDashboard();
  } else if (window.location.pathname.includes('student_dashboard.html')) {
    loadStudentDashboard();
  }
}

// --- 2. Auth Helpers ---

// Get Token from LocalStorage
const getToken = () => localStorage.getItem('smartedu-token');

// Fetch wrapper to attach Authorization Header automatically
async function apiRequest(url, options = {}) {
  const token = getToken();
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  return await fetch(url, {
    ...options,
    headers
  });
}

// --- 3. Login Logic ---
function handleLogin() {
  const loginForm = document.getElementById('loginForm');
  if (!loginForm) return;

  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const role = document.getElementById('role').value;
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const submitBtn = loginForm.querySelector('button');
    const errorMsg = document.getElementById('loginError');

    // UI Loading State
    submitBtn.disabled = true;
    submitBtn.textContent = 'Logging in...';
    if (errorMsg) errorMsg.style.display = 'none';

    try {
      const res = await apiRequest(`${API_BASE}/auth/login`, {
        method: 'POST',
        body: JSON.stringify({ email, password, role }) // Sending role hint
      });

      const data = await res.json();

      if (res.ok) {
        // Save Token & User Info
        localStorage.setItem('smartedu-token', data.token);
        localStorage.setItem('smartedu-user', JSON.stringify(data.user));
        localStorage.setItem('smartedu-role', data.user.role);

        showToast('Login Successful! Redirecting...');

        // Redirect based on role (matching user role from DB, not just form selection)
        setTimeout(() => {
          if (data.user.role === 'admin') window.location.href = 'admin_dashboard.html';
          else if (data.user.role === 'teacher') window.location.href = 'teacher_dashboard.html';
          else if (data.user.role === 'student') window.location.href = 'student_dashboard.html';
          else window.location.href = 'dashboard.html';
        }, 1000);

      } else {
        if (errorMsg) {
          errorMsg.textContent = data.message || 'Invalid credentials';
          errorMsg.style.display = 'block';
        }
        submitBtn.disabled = false;
        submitBtn.textContent = 'Login';
      }
    } catch (err) {
      console.error(err);
      if (errorMsg) {
        errorMsg.textContent = 'Connection Error. Try again.';
        errorMsg.style.display = 'block';
      }
      submitBtn.disabled = false;
      submitBtn.textContent = 'Login';
    }
  });
}

// --- 4. Logout Logic ---
function handleLogout() {
  const logoutBtn = document.getElementById('logoutBtn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', async () => {
      try {
        // Call API to invalidate token (optional but recommended)
        const token = getToken();
        if(token) {
           await apiRequest(`${API_BASE}/auth/logout`, { method: 'POST' });
        }

        // Clear Local Storage
        localStorage.removeItem('smartedu-token');
        localStorage.removeItem('smartedu-user');
        localStorage.removeItem('smartedu-role');

        showToast('Logged out successfully');
        window.location.href = '../index.html';

      } catch (err) {
        console.error(err);
        // Force logout even if API fails
        window.location.href = '../index.html';
      }
    });
  }
}

// --- 5. Navigation & Scroll ---
function handleNavbar() {
  const nav = document.querySelector('nav');
  
  // Check initial scroll position
  if (window.scrollY > 50) {
    nav.classList.add('scrolled');
  }

  window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
      nav.classList.add('scrolled');
    } else {
      nav.classList.remove('scrolled');
    }
  });
}

function handleSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const targetId = this.getAttribute('href').substring(1);
      const target = document.getElementById(targetId);
      if (target) {
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });
}

// --- 6. Dashboard Loaders ---

// Generic function to load stats via API
async function fetchDashboardStats(endpoint, containerId) {
  try {
    const res = await apiRequest(endpoint);
    const data = await res.json();
    const container = document.getElementById(containerId);

    if (container && res.ok) {
      renderStatsCards(data, container);
    } else if (res.status === 401) {
      window.location.href = '../index.html'; // Redirect if token expired
    }
  } catch (err) {
    console.error('Dashboard Error:', err);
  }
}

// Render Cards from JSON Data (Instead of raw JSON string)
function renderStatsCards(stats, container) {
  container.innerHTML = '';
  
  // Example: Expecting { students: 100, teachers: 10, classes: 5 }
  Object.entries(stats).forEach(([key, value]) => {
    const card = document.createElement('div');
    card.className = 'glassmorphism fade-in-section'; // Use our CSS class
    card.innerHTML = `
      <h3>${formatLabel(key)}</h3>
      <p style="font-size: 2rem; font-weight: 700;">${value}</p>
    `;
    container.appendChild(card);
  });
}

function formatLabel(key) {
  return key.charAt(0).toUpperCase() + key.slice(1).replace(/_/g, ' ');
}

// Loaders for Specific Dashboards
function loadAdminDashboard() {
  fetchDashboardStats('/admin/stats', 'admin-stats');
}

function loadTeacherDashboard() {
  fetchDashboardStats('/teacher/stats', 'teacher-stats');
}

function loadStudentDashboard() {
  fetchDashboardStats('/student/dashboard', 'student-stats');
}


// --- 7. Subscription Form (Simulation) ---
const subscribeForm = document.getElementById("subscribeForm");
if (subscribeForm) {
  subscribeForm.addEventListener("submit", (e) => {
    e.preventDefault();
    const name = document.getElementById("schoolName").value;
    const email = document.getElementById("schoolEmail").value;
    
    if (name && email) {
      // In a real app, use apiRequest here
      // await apiRequest('/api/subscribe', { method: 'POST', body: ... })
      
      showToast(`Thank you, ${name}! We've sent a confirmation to ${email}.`);
      subscribeForm.reset();
    }
  });
}

// --- 8. Utility: Toast Notification ---
function showToast(message, type = 'success') {
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  
  // Add minimal inline styles if not defined in CSS
  if (!document.querySelector('style[data-toast-styles]')) {
    const style = document.createElement('style');
    style.setAttribute('data-toast-styles', 'true');
    style.innerHTML = `
      .toast { position: fixed; top: 20px; right: 20px; padding: 15px 25px; background: #10b981; color: white; border-radius: 8px; z-index: 9999; animation: fadeIn 0.3s; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
      .toast-error { background: #ef4444; }
    `;
    document.head.appendChild(style);
  }

  document.body.appendChild(toast);
  
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}
