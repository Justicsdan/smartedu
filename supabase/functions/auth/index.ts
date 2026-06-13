import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function base64UrlEncode(str: string): string {
  return btoa(str).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

async function signJWT(payload: Record<string, unknown>, secret: string, expiresInSec: number): Promise<string> {
  const header = { alg: 'HS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const fullPayload = { ...payload, iat: now, exp: now + expiresInSec };
  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(fullPayload));
  const signingInput = `${headerB64}.${payloadB64}`;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sigBuf = await crypto.subtle.sign('HMAC', key, encoder.encode(signingInput));
  const sigArr = new Uint8Array(sigBuf);
  let sigStr = '';
  for (let i = 0; i < sigArr.length; i++) sigStr += String.fromCharCode(sigArr[i]);
  const sigB64 = base64UrlEncode(sigStr);
  return `${signingInput}.${sigB64}`;
}

function extractId(rpcData: unknown): string | null {
  if (!rpcData) return null;
  if (Array.isArray(rpcData)) return rpcData[0]?.id ?? null;
  return (rpcData as Record<string, unknown>)?.id as string ?? null;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }

  const jwtSecret = Deno.env.get('JWT_SECRET');
  if (!jwtSecret) {
    console.error('JWT_SECRET not set');
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const db = createClient(supabaseUrl, serviceRoleKey);

  try {
    const { role, username, password } = await req.json();
    if (!role || !username || !password) {
      return new Response(JSON.stringify({ error: 'role, username, and password are required' }), {
        status: 400,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    let user: Record<string, unknown> | null = null;
    let jwtRole = '';
    let jwtSchoolId = '';
    let jwtUserId = '';
    let loginTable = '';
    let loginId = '';

    switch (role) {
      case 'student': {
        const { data, error } = await db
          .from('students')
          .select('id, school_id, first_name, last_name, middle_name, class_id, admission_no, passport_url, gender, date_of_birth, school_level, is_active')
          .eq('admission_no', username)
          .eq('pin', password)
          .eq('is_active', true)
          .maybeSingle();
        if (error || !data) {
          return new Response(JSON.stringify({ error: 'Invalid admission number or PIN', detail: error?.message }), {
            status: 401,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        user = data;
        jwtRole = 'student';
        jwtSchoolId = data.school_id as string;
        jwtUserId = data.id as string;
        loginTable = 'students';
        loginId = data.id as string;
        break;
      }

      case 'teacher': {
        const { data: rpcData, error: rpcError } = await db.rpc('login_teacher', { p_username: username, p_password: password });
        if (rpcError) {
          return new Response(JSON.stringify({ error: 'Login failed', detail: rpcError.message }), {
            status: 401,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        const teacherId = extractId(rpcData);
        if (!teacherId) {
          return new Response(JSON.stringify({ error: 'Invalid username or password', detail: 'RPC returned no ID', rpcRaw: rpcData }), {
            status: 401,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        const { data: profile, error: profErr } = await db
          .from('teachers')
          .select('id, school_id, first_name, last_name, middle_name, staff_id, passport_url, gender, email, phone, department, qualification, is_active, home_address')
          .eq('id', teacherId)
          .single();
        if (profErr || !profile) {
          return new Response(JSON.stringify({ error: 'Profile fetch failed', detail: profErr?.message, teacherId }), {
            status: 500,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        user = profile;
        jwtRole = 'teacher';
        jwtSchoolId = profile.school_id as string;
        jwtUserId = profile.id as string;
        loginTable = 'teachers';
        loginId = profile.id as string;
        break;
      }

      case 'school_admin': {
        const { data: rpcData, error: rpcError } = await db.rpc('login_school_admin', { p_username: username, p_password: password });
        if (rpcError) {
          return new Response(JSON.stringify({ error: 'Login failed', detail: rpcError.message }), {
            status: 401,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        const schoolId = extractId(rpcData);
        if (!schoolId) {
          return new Response(JSON.stringify({ error: 'Invalid username or password', detail: 'RPC returned no ID', rpcRaw: rpcData }), {
            status: 401,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        const { data: school, error: schErr } = await db
          .from('schools')
          .select('id, school_code, name, logo_url, motto, location, address, official_phone, official_email, website, principal_signature_url, school_stamp_url, whatsapp, school_type, is_active, subscription_plan, subscription_status')
          .eq('id', schoolId)
          .single();
        if (schErr || !school) {
          return new Response(JSON.stringify({ error: 'School fetch failed', detail: schErr?.message, schoolId }), {
            status: 500,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        user = school;
        jwtRole = 'school_admin';
        jwtSchoolId = school.id as string;
        jwtUserId = school.id as string;
        loginTable = 'schools';
        loginId = school.id as string;
        break;
      }

      case 'super_admin': {
        const { data: rpcData, error: rpcError } = await db.rpc('login_super_admin', { p_username: username, p_password: password });
        if (rpcError) {
          return new Response(JSON.stringify({ error: 'Login failed', detail: rpcError.message }), {
            status: 401,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        const saId = extractId(rpcData);
        if (!saId) {
          return new Response(JSON.stringify({ error: 'Invalid username or password', detail: 'RPC returned no ID', rpcRaw: rpcData }), {
            status: 401,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        const { data: sa, error: saErr } = await db
          .from('super_admins')
          .select('id, username, name, is_active')
          .eq('id', saId)
          .single();
        if (saErr || !sa) {
          return new Response(JSON.stringify({ error: 'Profile fetch failed', detail: saErr?.message, saId }), {
            status: 500,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          });
        }
        user = sa;
        jwtRole = 'super_admin';
        jwtSchoolId = '';
        jwtUserId = sa.id as string;
        loginTable = 'super_admins';
        loginId = sa.id as string;
        break;
      }

      default:
        return new Response(JSON.stringify({ error: `Unknown role: ${role}` }), {
          status: 400,
          headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
        });
    }

    if (loginTable && loginId) {
      await db.from(loginTable).update({ last_login: new Date().toISOString() }).eq('id', loginId);
    }

    const token = await signJWT(
      { sub: jwtUserId, role: jwtRole, school_id: jwtSchoolId },
      jwtSecret,
      86400,
    );

    return new Response(JSON.stringify({ token, user }), {
      status: 200,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Auth error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error', detail: String(err) }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }
});
