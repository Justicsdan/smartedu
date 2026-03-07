/**
 * Authentication & Authorization Middleware
 * Handles JWT verification, User lookup, and Role-Based Access Control (RBAC).
 */

const jwt = require("jsonwebtoken");
const User = require("../models/User");

// --- Helper: Extract Token from Header ---
const getToken = (req) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return null;
  }
  
  // Return token string (remove "Bearer " prefix)
  return authHeader.split(" ")[1];
};

// --- 1. Main Auth Middleware ---
const protect = async (req, res, next) => {
  const token = getToken(req);

  // 1. Check if Token exists
  if (!token) {
    return res.status(401).json({ message: "No token, authorization denied" });
  }

  try {
    // 2. Verify Token Signature & Expiry
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 3. Database Check (CRITICAL: Ensures user still exists and wasn't deleted/banned)
    // We fetch from DB instead of just trusting the JWT payload to handle
    // account suspensions or role changes immediately.
    const user = await User.findById(decoded.id).select("-password");

    if (!user) {
      return res.status(401).json({ message: "User not found. Token invalid." });
    }

    // 4. Attach User to Request Object
    // Now controllers can access via `req.user.id`, `req.user.role`, etc.
    req.user = user;

    next();

  } catch (error) {
    // Handle JWT specific errors (Expired, Malformed)
    console.error("Auth Error:", error);
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: "Session expired. Please login again." });
    }
    
    return res.status(401).json({ message: "Not authorized. Token failed." });
  }
};

// --- 2. Role Middleware Factory ---
// A helper to generate role-checking middleware dynamically.
// Reduces code duplication for 'adminOnly', 'teacherOnly', etc.
const checkRole = (allowedRole) => {
  return (req, res, next) => {
    // req.user is populated by the 'protect' middleware
    if (req.user && req.user.role === allowedRole) {
      next();
    } else {
      res.status(403).json({ 
        message: `Access denied. ${allowedRole}s only.`,
        required: allowedRole,
        current: req.user?.role 
      });
    }
  };
};

// --- 3. Exported Middleware ---
module.exports = {
  protect,          // Apply to all protected routes
  
  adminOnly: checkRole('admin'),
  teacherOnly: checkRole('teacher'),
  studentOnly: checkRole('student'),
};
