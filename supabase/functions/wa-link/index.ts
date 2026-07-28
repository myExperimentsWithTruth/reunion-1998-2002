// Serves the committee wa.me link at runtime. The number lives only in the
// WA_NUMBER function secret, never in the public repo or page source.
// CORS is open because it gates nothing here: the endpoint is public by design
// (same as the page's WhatsApp button), and curl ignores CORS anyway.
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
};

Deno.serve((req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  const n = Deno.env.get('WA_NUMBER') ?? '';
  if (!/^\d{8,15}$/.test(n)) {
    return new Response(JSON.stringify({ error: 'not configured' }), {
      status: 404,
      headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  }
  return new Response(JSON.stringify({ url: `https://wa.me/${n}` }), {
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
});
