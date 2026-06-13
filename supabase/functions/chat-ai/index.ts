import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

const SYSTEM_PROMPT = `You are a help assistant for a school management platform called SmartEdu. You ONLY answer questions about how to use this platform. Your scope includes:
- Entering and managing student scores
- Publishing and viewing student results
- Managing students, teachers, and classes
- Setting up subjects and assignments
- Managing academic sessions and terms
- Viewing attendance records
- Using grading systems and assessment types
- Navigating the dashboard and settings
- Understanding behavioral ratings
- CBT exam creation and management
- School branding and profile settings
- Student profile information

For ANY question NOT related to using this school management platform (such as general knowledge, homework help, lesson plans, coding, personal advice, jokes, etc.), reply exactly: "I can only help with questions about using the school management system."
Keep answers concise and practical. Use step-by-step instructions when explaining how to do something.`;

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
  try {
    const { messages, schoolContext } = await req.json();
    if (!messages || !Array.isArray(messages)) {
      return new Response(JSON.stringify({ error: 'messages array is required' }), {
        status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }
    const apiKey = Deno.env.get('GROQ_API_KEY');
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'API key not configured' }), {
        status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // Build system message with school context if provided
    let systemContent = SYSTEM_PROMPT;
    if (schoolContext) {
      systemContent += `\n\nCurrent school context: ${schoolContext}`;
    }

    // Always inject system message as first message, discard any client-sent system messages
    const filteredMessages = messages.filter((m: any) => m.role !== 'system');
    const finalMessages = [
      { role: 'system', content: systemContent },
      ...filteredMessages,
    ];

    const response = await fetch(GROQ_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + apiKey },
      body: JSON.stringify({ model: 'llama-3.3-70b-versatile', messages: finalMessages, temperature: 0.7, max_tokens: 512 }),
    });
    const data = await response.json();
    if (!response.ok) {
      return new Response(JSON.stringify({ error: data.error?.message || 'Groq API error' }), {
        status: response.status, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }
    const reply = data.choices?.[0]?.message?.content || 'No response generated';
    return new Response(JSON.stringify({ reply }), {
      status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Internal server error' }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
});
