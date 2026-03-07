/**
 * Request Validation Middleware
 * Uses express-validator to check incoming data (Body, Params, Query)
 */

const { validationResult } = require("express-validator");

/**
 * Main Middleware Function
 * This assumes validation chains (body(), param(), etc.) were run *before* this middleware
 * in the route definition.
 */
const validateRequest = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    // No errors found, proceed to controller
    return next();
  }

  // Validation Failed
  // 422 Unprocessable Entity is the standard status for validation errors
  return res.status(422).json({
    success: false,
    message: "Validation failed",
    errors: errors.array({
      // Optional: Flatten errors to a cleaner format
      // This converts [{ msg: "Email is bad", param: "email" }]
      // To a key-value object: { "email": "Email is bad" }
      onlyFirstError: true
    })
  });
};

module.exports = validateRequest;
