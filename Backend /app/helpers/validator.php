<?php

if (!function_exists('validator')) {
    /**
     * Validate input data against rules.
     *
     * Rules format: 'field' => 'rule1|rule2:param|...'
     * Supported rules:
     * - required
     * - email
     * - min:value (Length for strings, Value for numbers)
     * - max:value (Length for strings, Value for numbers)
     * - numeric
     * - integer (Strict, no decimals)
     * - in:value1,value2,...
     * - date (YYYY-MM-DD - checks validity)
     * - alphanumeric (Strict: only A-Z, 0-9)
     * - alpha_dash (Letters, numbers, dashes, underscores)
     * - regex:pattern
     * - confirmed (Matches field_confirmation)
     *
     * @param array $data   Input data (usually from JSON or form)
     * @param array $rules  Validation rules
     * @return array|null   Array of errors (field => message) or null if valid
     */
    function validator(array $data, array $rules): ?array
    {
        $errors = [];

        foreach ($rules as $field => $ruleString) {
            $fieldRules = explode('|', $ruleString);
            $value = $data[$field] ?? null;

            foreach ($fieldRules as $rule) {
                $parts = explode(':', $rule, 2);
                $ruleName = $parts[0];
                $parameter = $parts[1] ?? null;

                $error = null;

                switch ($ruleName) {
                    case 'required':
                        if ($value === null || $value === '' || (is_array($value) && empty($value))) {
                            $error = "$field is required";
                        }
                        break;

                    case 'email':
                        if ($value !== null && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
                            $error = "$field must be a valid email address";
                        }
                        break;

                    case 'min':
                        if ($value !== null) {
                            $length = 0;
                            // IMPROVEMENT: If it represents a number, compare values. Otherwise, compare length.
                            if (is_numeric($value)) {
                                $length = (int)$value;
                            } elseif (is_string($value)) {
                                $length = mb_strlen($value);
                            } elseif (is_array($value)) {
                                $length = count($value);
                            }

                            if ($length < $parameter) {
                                $error = "$field must be at least $parameter " . (is_numeric($value) ? '' : 'characters');
                            }
                        }
                        break;

                    case 'max':
                        if ($value !== null) {
                            $length = 0;
                            if (is_numeric($value)) {
                                $length = (int)$value;
                            } elseif (is_string($value)) {
                                $length = mb_strlen($value);
                            } elseif (is_array($value)) {
                                $length = count($value);
                            }

                            if ($length > $parameter) {
                                $error = "$field must not exceed $parameter " . (is_numeric($value) ? '' : 'characters');
                            }
                        }
                        break;

                    case 'numeric':
                        if ($value !== null && !is_numeric($value)) {
                            $error = "$field must be numeric";
                        }
                        break;

                    case 'integer':
                        // IMPROVEMENT: Ensure strictly no decimals or scientific notation chars in strings
                        if ($value !== null && (!is_numeric($value) || (string)(int)$value !== (string)$value)) {
                            $error = "$field must be an integer";
                        }
                        break;

                    case 'in':
                        $allowed = explode(',', $parameter);
                        if ($value !== null && !in_array($value, $allowed, true)) {
                            $error = "$field must be one of: " . implode(', ', $allowed);
                        }
                        break;

                    case 'date':
                        // IMPROVEMENT: Use DateTime to check actual validity (e.g. no Feb 30)
                        if ($value !== null) {
                            $format = 'Y-m-d';
                            $date = DateTime::createFromFormat($format, $value);
                            if (!$date || $date->format($format) !== $value) {
                                $error = "$field must be a valid date (YYYY-MM-DD)";
                            }
                        }
                        break;

                    case 'alphanumeric':
                        // IMPROVEMENT: Strict check (no spaces/dashes)
                        if ($value !== null && !ctype_alnum((string)$value)) {
                            $error = "$field must contain only letters and numbers";
                        }
                        break;

                    case 'alpha_dash':
                        // NEW: Allow letters, numbers, dashes, underscores (common for usernames/slugs)
                        if ($value !== null && !preg_match('/^[a-zA-Z0-9_-]+$/', $value)) {
                            $error = "$field may only contain letters, numbers, dashes and underscores";
                        }
                        break;

                    case 'regex':
                        // NEW: Allow custom regex patterns
                        if ($value !== null && !preg_match($parameter, $value)) {
                            $error = "$field format is invalid";
                        }
                        break;

                    case 'confirmed':
                        // NEW: Check against field_confirmation (e.g. password)
                        $confirmField = $field . '_confirmation';
                        if ($value !== null && (!isset($data[$confirmField]) || $data[$confirmField] !== $value)) {
                            $error = "$field confirmation does not match";
                        }
                        break;

                    default:
                        // Unknown rule
                        break;
                }

                if ($error) {
                    $errors[$field][] = $error;
                }
            }
        }

        // Return only the first error per field for cleaner output
        foreach ($errors as $field => $messages) {
            $errors[$field] = $messages[0]; 
        }

        return empty($errors) ? null : $errors;
    }
}
