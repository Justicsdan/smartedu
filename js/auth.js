/**
 * SmartEdu Login Handler
 * Handles authentication for SuperAdmin, Admin, Teacher, and Student.
 */

// Configuration
const API_BASE_URL = 'http://localhost:8000/api'; // Change to your API URL

document.addEventListener('DOMContentLoaded', () => {

  // --- Helper: Toast Notification (Better than Alert) ---
  const showToast = (message, type = 'success') => {
    // Create element
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;

    // Styles (Inline for simplicity, ideally move to CSS)
    Object.assign(toast.style, {
      position: 'fixed',
      top: '20px',
      right: '20px',
      background: type === 'error' ? '#ef4444' : '#10b981',
      color: 'white',
      padding: '15px 25px',
      borderRadius: '8px',
      boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
      zIndex: '1000',
      transform: 'translateX(120%)',
      transition: 'transform 0.3s ease-in-out',
      fontWeight: '600'
    });

    document.body.appendChild(toast);

    // Animate In
    requestAnimationFrame(() => {
      toast.style.transform = 'translateX(0)';
    });

    // Remove after 3 seconds
    setTimeout(() => {
      toast.style.transform = 'translateX(120%)';
      toast.addEventListener('transitionend', () => toast.remove());
    }, 3000);
  };

  // --- Helper: Set Loading State ---
  const setLoading = (form, isLoading) => {
    const btn = form.querySelector('button[type="submit"]');
    if (!btn) return;

    if (isLoading) {
      btn.disabled = true;
      btn.textContent = 'Authenticating...';
      btn.style.opacity = '0.7';
    } else {
      btn.disabled = false;
      btn.textContent = 'Login';
      btn.style.opacity = '1';
    }
  };

  // --- Main Login Logic ---
  const handleLogin = async (formId, portal) => {
    const form = document.getElementById(formId);

    if (!form) {
      console.error(`Form with ID "${formId}" not found.`);
      return;
    }

    form.addEventListener('submit', async (e) => {
      e.preventDefault();

      // Basic Validation
      let payload = { portal }; // { portal: "student" | "admin" etc. }
      
      if (portal === 'student') {
        // Student uses Username + PIN
        if (!form.username.value.trim() || !form.pin.value.trim()) {
          showToast('Please enter Username and PIN', 'error');
          return;
        }
        payload.username = form.username.value.trim();
        payload.password = form.pin.value.trim(); // Map 'pin' to 'password' for API consistency
      } else {
        // Others use Email + Password
        if (!form.email.value.trim() || !form.password.value.trim()) {
          showToast('Please enter Email and Password', 'error');
          return;
        }
        payload.email = form.email.value.trim();
        payload.password = form.password.value.trim();
      }

      // Start Loading
      setLoading(form, true);

      try {
        const res = await fetch(`${API_BASE_URL}/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });

        const data = await res.json();

        // Stop Loading
        setLoading(form, false);

        if (res.ok) {
          // Save Token
          if (data.token) {
            localStorage.setItem(`${portal}-token`, data.token);
          }
          
          // Save User Data (Optional, for sidebar display)
          if (data.user) {
            localStorage.setItem('current-user', JSON.stringify(data.user));
          }

          showToast(`Welcome, ${data.user?.name || 'User'}!`);

          // Redirect based on portal
          const routes = {
            'super-admin': '../pages/super_admin_dashboard.html',
            'school-admin': '../pages/admin_dashboard.html',
            'teacher': '../pages/teacher_dashboard.html',
            'student': '../pages/student_dashboard.html'
          };

          if (routes[portal]) {
            setTimeout(() => {
              window.location.href = routes[portal];
            }, 1000); // 1s delay to let user see success message
          } else {
            showToast('Unknown portal type', 'error');
          }
        } else {
          showToast(data.message || 'Invalid credentials', 'error');
        }

      } catch (err) {
        setLoading(form, false);
        console.error('Login Error:', err);
        showToast('Connection failed. Check console.', 'error');
      }
    });
  };

  // --- Initialize ---
  handleLogin('super-admin-login', 'super-admin');
  handleLogin('admin-login', 'school-admin');
  handleLogin('teacher-login', 'teacher');
  handleLogin('student-login', 'student');

});
