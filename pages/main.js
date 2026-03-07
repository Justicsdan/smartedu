<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="SmartEdu - Secure Login Portal">
  <title>SmartEdu - Secure Login</title>
  
  <!-- PWA Manifest (for mobile) -->
  <link rel="manifest" href="/manifest.json">
  <meta name="theme-color" content="#6366f1">
  
  <!-- Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  
  <!-- Icons -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

  <style>
    /* Your existing beautiful styles remain unchanged */
    /* ... (keep all your CSS exactly as is) ... */
    
    /* Add subtle background pattern */
    body::before {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0; bottom: 0;
      background: radial-gradient(circle at 20% 80%, rgba(99, 102, 241, 0.1) 0%, transparent 50%),
                  radial-gradient(circle at 80% 20%, rgba(139, 92, 246, 0.1) 0%, transparent 50%);
      pointer-events: none;
      z-index: -1;
    }
  </style>
</head>
<body>

  <div class="container">
    <!-- Header -->
    <header class="header">
      <div class="logo-area">
        <i class="fas fa-graduation-cap logo-icon"></i>
        <span class="logo-text">SmartEdu</span>
      </div>
    </header>

    <!-- Login Section -->
    <section class="login-card">
      <div class="login-header">
        <h2>Welcome Back</h2>
        <p>Please select your user type and log in securely.</p>
      </div>

      <!-- Role Selector Tabs -->
      <div class="login-tabs">
        <button class="tab-btn active" data-role="super_admin" id="tab-superadmin">Super Admin</button>
        <button class="tab-btn" data-role="admin" id="tab-admin">School Admin</button>
        <button class="tab-btn" data-role="teacher" id="tab-teacher">Teacher</button>
        <button class="tab-btn" data-role="student" id="tab-student">Student</button>
      </div>

      <!-- Login Form -->
      <form id="loginForm" class="login-form">
        <!-- Email & Password (for all except student) -->
        <div id="input-group-email" class="input-group">
          <label for="email">Email Address</label>
          <input type="email" id="email" class="input-field" placeholder="name@school.com" autocomplete="email" required>
        </div>

        <div id="input-group-password" class="input-group">
          <label for="password">Password</label>
          <input type="password" id="password" class="input-field" placeholder="••••••••" autocomplete="current-password" required>
        </div>

        <!-- Student Only -->
        <div id="input-group-matric" class="input-group" style="display: none;">
          <label for="matric">Matric Number</label>
          <input type="text" id="matric" class="input-field" placeholder="2024/1001" autocomplete="off">
        </div>

        <div id="input-group-pin" class="input-group" style="display: none;">
          <label for="pin">4-Digit PIN</label>
          <input type="password" id="pin" class="input-field" placeholder="••••" maxlength="4" autocomplete="off">
        </div>

        <div id="form-error" class="form-error"></div>

        <button type="submit" id="submitBtn" class="btn-submit">
          <i class="fas fa-sign-in-alt" style="margin-right: 8px;"></i>
          <span id="submitText">Login to Portal</span>
        </button>
      </form>

      <div style="text-align: center; margin-top: 2rem;">
        <a href="/" style="color: var(--text-muted); font-size: 0.9rem; text-decoration: none;">
          ← Back to Home
        </a>
      </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
      <p>SmartEdu Systems • Jos, Plateau State</p>
      <p>Phone: 07080304822</p>
      <p><a href="mailto:support@smartedu.com">Need Help? Contact Support</a></p>
      <p>&copy; 2026 SmartEdu. All Rights Reserved.</p>
    </footer>
  </div>

  <!-- Toast Container -->
  <div class="toast-container" id="toastContainer"></div>

  <script>
    const API_BASE_URL = '/api'; // Relative path — works in production
    let currentRole = 'super_admin';

    // DOM Elements
    const loginForm = document.getElementById('loginForm');
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    const matricInput = document.getElementById('matric');
    const pinInput = document.getElementById('pin');
    const submitBtn = document.getElementById('submitBtn');
    const submitText = document.getElementById('submitText');
    const errorDiv = document.getElementById('form-error');

    // Role Switching
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        currentRole = btn.dataset.role;
        
        // Update active tab
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        // Reset form
        loginForm.reset();
        errorDiv.style.display = 'none';
        submitBtn.disabled = false;
        submitText.textContent = 'Login to Portal';

        // Show/hide fields
        if (currentRole === 'student') {
          document.getElementById('input-group-email').style.display = 'none';
          document.getElementById('input-group-password').style.display = 'none';
          document.getElementById('input-group-matric').style.display = 'block';
          document.getElementById('input-group-pin').style.display = 'block';
        } else {
          document.getElementById('input-group-email').style.display = 'block';
          document.getElementById('input-group-password').style.display = 'block';
          document.getElementById('input-group-matric').style.display = 'none';
          document.getElementById('input-group-pin').style.display = 'none';
        }
      });
    });

    // Form Submit
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      errorDiv.style.display = 'none';

      submitBtn.disabled = true;
      submitText.textContent = 'Authenticating...';

      let payload = {};
      let endpoint = '/auth/login';

      if (currentRole === 'student') {
        payload = {
          matric: matricInput.value.trim(),
          pin: pinInput.value.trim()
        };
        endpoint = '/auth/student-login';
      } else {
        payload = {
          email: emailInput.value.trim(),
          password: passwordInput.value
        };
      }

      try {
        const res = await fetch(API_BASE_URL + endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });

        const data = await res.json();

        if (res.ok) {
          showToast('Login successful! Redirecting...', 'success');
          
          localStorage.setItem('smartedu-token', data.token);
          localStorage.setItem('smartedu-role', currentRole);
          localStorage.setItem('smartedu-user', JSON.stringify(data.user));

          setTimeout(() => {
            const dashboards = {
              super_admin: '/pages/superadmin/dashboard.html',
              admin: '/pages/admin/dashboard.html',
              teacher: '/pages/teacher/dashboard.html',
              student: '/pages/student/dashboard.html'
            };
            window.location.href = dashboards[currentRole] || '/pages/teacher/dashboard.html';
          }, 1500);
        } else {
          showError(data.message || 'Invalid credentials');
          resetSubmit();
        }
      } catch (err) {
        showError('Network error. Please try again.');
        resetSubmit();
      }
    });

    function showError(msg) {
      errorDiv.textContent = msg;
      errorDiv.style.display = 'block';
    }

    function resetSubmit() {
      submitBtn.disabled = false;
      submitText.textContent = 'Login to Portal';
    }

    function showToast(msg, type = 'success') {
      const container = document.getElementById('toastContainer');
      const toast = document.createElement('div');
      toast.className = `toast ${type}`;
      toast.innerHTML = `<i class="fas fa-${type === 'success' ? 'check' : 'exclamation'}-circle"></i> <span>${msg}</span>`;
      container.appendChild(toast);

      setTimeout(() => toast.remove(), 4000);
    }
  </script>
</body>
</html>
