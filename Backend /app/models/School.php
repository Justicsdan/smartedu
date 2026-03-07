<?php

namespace App\Models;

use App\Core\Model;
use PDO;

/**
 * Central model for schools in the multi-tenant SmartEdu platform.
 *
 * Each school is fully isolated and customizable (branding, grading, type).
 *
 * @property int    $id
 * @property string $name
 * @property string $code           Unique across platform
 * @property string $email
 * @property string $logo_path      Path to uploaded logo
 * @property string $motto
 * @property string $address
 * @property string $phone
 * @property string $school_type    'day' or 'boarding'
 * @property string $grading_scale  JSON string of custom grade ranges
 * @property string $status         'active' or 'inactive'
 * @property string $created_at
 */
class School extends Model
{
    protected string $table = 'schools';
    protected string $primaryKey = 'id';

    /**
     * Get all schools with comprehensive stats for Super Admin dashboard
     */
    public function allWithStats(): array
    {
        // ... your existing excellent query (unchanged)
    }

    // ... your other methods remain unchanged ...

    /**
     * Get custom grading scale for a school
     *
     * @param int $school_id
     * @return array Default or custom grade ranges
     */
    public function getGradingScale(int $school_id): array
    {
        $school = $this->find($school_id);

        if (!$school || empty($school['grading_scale'])) {
            // Default WAEC-style grading
            return [
                'A+' => [90, 100],
                'A'  => [80, 89],
                'B'  => [70, 79],
                'C'  => [60, 69],
                'D'  => [50, 59],
                'E'  => [40, 49],
                'F'  => [0, 39]
            ];
        }

        $scale = json_decode($school['grading_scale'], true);

        return is_array($scale) ? $scale : $this->getDefaultGradingScale();
    }

    /**
     * Check if school is boarding type
     */
    public function isBoarding(int $school_id): bool
    {
        $school = $this->find($school_id);
        return $school && $school['school_type'] === 'boarding';
    }

    /**
     * Get full branding info for reports/PDFs
     */
    public function getBranding(int $school_id): array
    {
        $school = $this->find($school_id);

        if (!$school) {
            return [];
        }

        return [
            'name'       => $school['name'],
            'code'       => $school['code'],
            'logo_path'  => $school['logo_path'] ?? null,
            'logo_url'   => $school['logo_path'] ? '/uploads/schools/' . $school['logo_path'] : null,
            'motto'      => $school['motto'] ?? '',
            'address'    => $school['address'] ?? '',
            'phone'      => $school['phone'] ?? '',
            'email'      => $school['email'] ?? '',
            'school_type'=> $school['school_type'] ?? 'day',
            'grading_scale' => $this->getGradingScale($school_id)
        ];
    }

    /**
     * Override create - handle new branding fields
     */
    public function create(array $data): int|string
    {
        if (empty($data['code'])) {
            throw new \Exception('School code is required.');
        }

        $data['code'] = strtoupper(trim($data['code']));

        $existing = $this->findBy('code', $data['code']);
        if ($existing) {
            throw new \Exception("School code '{$data['code']}' already exists.");
        }

        // Set defaults
        $data['status'] = $data['status'] ?? 'active';
        $data['school_type'] = $data['school_type'] ?? 'day';
        $data['created_at'] = date('Y-m-d H:i:s');

        return parent::create($data);
    }

    /**
     * Override update - handle branding updates
     */
    public function update(int $id, array $data): bool
    {
        if (!empty($data['code'])) {
            $data['code'] = strtoupper(trim($data['code']));

            $existing = $this->where([
                'code' => $data['code'],
                ['id', '!=', $id]
            ]);

            if (!empty($existing)) {
                throw new \Exception("School code '{$data['code']}' is already in use.");
            }
        }

        return parent::update($id, $data);
    }

    private function getDefaultGradingScale(): array
    {
        return [
            'A+' => [90, 100],
            'A'  => [80, 89],
            'B'  => [70, 79],
            'C'  => [60, 69],
            'D'  => [50, 59],
            'E'  => [40, 49],
            'F'  => [0, 39]
        ];
    }
}
