/**
 * SmartEdu Login Handler
 * Handles authentication for SuperAdmin, Admin, Teacher, and Student.
 */

document.addEventListener("DOMContentLoaded", () => {
  
  // 1. Map Form IDs to User Roles
  const forms = {
    "super-admin-login": "superadmin",
    "admin-login": "admin",
    "teacher-login": "teacher",
    "student-login": "student",
  };

  // 2. Helper: Toast Notification (Better than alert())
  const showToast = (message, type = 'success') => {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;

    // Inline styles for portability
    Object.assign(toast.style, {
      position: 'fixed',
      top: '20px',
      right: '20px',
      background: type === 'error' ? '#ef4444' : '#10b981',
      color: '#fff',
      padding: '12px 20px',
      borderRadius: '8px',
      zIndex: '10000',
      transform: 'translateX(120%)',
      transition: 'transform 0.3s ease',
      boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
    });

    document.body.appendChild(toast);
    
    // Animate In
    requestAnimationFrame(() => toast.style.transform = 'translateX(0)');

    // Remove after 3s
    setTimeout(() => {
      toast.style.transform = 'translateX(120%)';
      toast.addEventListener('transitionend', () => toast.remove());
    }, 3000);
  };

  // 3. Helper: Get Input Value Safely
  const getVal = (name) => {
    const el = document.querySelector(`input[name="${name}"]`);
    return el ? el.value.trim() : '';
  };

  // 4. Main Event Listener Loop
  Object.entries(forms).forEach(([formId, role]) => {
    const form = document.getElementById(formId);
    if (!form) {
      console.warn(`Form with ID ${formId} not found.`);
      return;
    }

    form.addEventListener("submit", async (e) => {
      e.preventDefault();

      // UI Elements
      const errorMessage = form.querySelector(".error-message");
      const submitBtn = form.querySelector('button[type="submit"]');

      // Clear Error & Set Loading
      if (errorMessage) {
        errorMessage.style.display = "none";
        errorMessage.textContent = "";
        errorMessage.classList.remove("shake"); // Remove animation class if exists
      }

      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = "Authenticating...";
      }

      // Prepare Payload
      let payload = { role }; // Send role to backend for validation

      if (role === 'student') {
        // Student Login: Username (Matric) + PIN
        const username = getVal('username');
        const pin = getVal('pin');
        
        if (!username || !pin) {
          if (errorMessage) {
            errorMessage.textContent = "Please enter Matric Number and PIN.";
            errorMessage.style.display = "block";
          }
          // Reset Button
          if (submitBtn) { submitBtn.disabled = false; submitBtn.textContent = "Login"; }
          return;
        }

        payload.username = username;
        payload.password = pin; // Map 'pin' to 'password' field for API

      } else {
        // Admin/Teacher/SuperAdmin: Email + Password
        const email = getVal('email');
        const password = getVal('password');

        if (!email || !password) {
          if (errorMessage) {
            errorMessage.textContent = "Please enter Email and Password.";
            errorMessage.style.display = "block";
          }
          if (submitBtn) { submitBtn.disabled = false; submitBtn.textContent = "Login"; }
          return;
        }

        payload.email = email;
        payload.password = password;
      }

      try {
        // Send Request
        const response = await fetch("/api/login", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        const data = await response.json();

        // Reset Button
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = "Login";
        }

        if (response.ok) {
          // --- SUCCESS ---
          
          // 1. Store Token (Crucial for authenticated requests)
          if (data.token) {
            localStorage.setItem('smartedu-token', data.token);
            localStorage.setItem('smartedu-user', JSON.stringify(data.user));
          }

          // 2. Show Success Message
          showToast(`Welcome, ${data.user?.name || 'User'}!`);

          // 3. Redirect Logic
          const redirectUrls = {
            superadmin: "../pages/superadmin_dashboard.html",
            admin: "../pages/admin_dashboard.html",
            teacher: "../pages/teacher_dashboard.html",
            student: "../pages/student_dashboard.html"
          };

          const target = redirectUrls[role];
          if (target) {
            setTimeout(() => {
              window.location.href = target;
            }, 1000); // 1s delay to see the toast
          } else {
            console.error("Unknown role for redirect:", role);
          }

        } else {
          // --- FAILURE ---
          if (errorMessage) {
            errorMessage.textContent = data.message || "Invalid credentials provided.";
            errorMessage.style.display = "block";
            
            // Optional: Add a shake animation via CSS class
            // errorMessage.classList.add("shake"); 
          }
        }

      } catch (err) {
        // --- NETWORK ERROR ---
        console.error("Login Error:", err);
        
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = "Login";
        }
        
        if (errorMessage) {
          errorMessage.textContent = "Network error. Please check your connection.";
          errorMessage.style.display = "block";
        }
      }
    });
  });
});
