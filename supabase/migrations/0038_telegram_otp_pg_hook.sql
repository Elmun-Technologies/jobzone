-- 0037_telegram_otp_pg_hook.sql
-- Telegram-OTP delivery as a *Postgres* Send-SMS auth hook — an alternative to
-- the `send-sms-hook` Edge Function that needs no function deploy and no
-- Management-API access to set up (adopted at go-live when functions deploy was
-- blocked by an access-token 403). Supabase Auth still generates, stores,
-- rate-limits and verifies the OTP itself; this hook only delivers the code as
-- a Telegram message via Telegram Gateway (gateway.telegram.org).
--
-- Wire-up (Dashboard):
--   1. Run:  alter database postgres set app.telegram_gateway_token = '<token>';
--   2. Authentication -> Auth Hooks -> Add hook -> Send SMS hook ->
--      type Postgres -> schema public -> function send_sms_telegram.
--   3. Authentication -> Sign In / Providers -> Phone -> Enable.
--
-- Trade-off vs the HTTPS hook: pg_net posts asynchronously (fire-and-forget),
-- so a Telegram-side delivery failure is not surfaced to the sign-in call —
-- check net._http_response when debugging. The HTTPS variant
-- (supabase/functions/send-sms-hook) remains in the repo and fails loudly;
-- either can be selected in the dashboard.

create extension if not exists pg_net with schema extensions;

create or replace function public.send_sms_telegram(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text := current_setting('app.telegram_gateway_token', true);
  v_phone text := event->'user'->>'phone';
  v_otp   text := event->'sms'->>'otp';
begin
  if v_token is null or v_token = '' then
    return jsonb_build_object('error', jsonb_build_object(
      'http_code', 500,
      'message', 'app.telegram_gateway_token is not configured'));
  end if;
  if v_phone is null or v_otp is null then
    return jsonb_build_object('error', jsonb_build_object(
      'http_code', 400,
      'message', 'missing phone or otp in hook payload'));
  end if;

  -- Auth stores phones without the leading '+'; Gateway wants E.164 with it.
  if left(v_phone, 1) <> '+' then
    v_phone := '+' || v_phone;
  end if;

  -- Reuse Supabase's own OTP as the delivered code so verifyOtp() checks the
  -- same value the user received.
  perform net.http_post(
    url     := 'https://gateway.telegram.org/sendVerificationMessage',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'Authorization', 'Bearer ' || v_token),
    body    := jsonb_build_object('phone_number', v_phone, 'code', v_otp)
  );

  return '{}'::jsonb;
end;
$$;

-- Only the auth server may invoke the hook.
grant usage on schema public to supabase_auth_admin;
grant execute on function public.send_sms_telegram(jsonb) to supabase_auth_admin;
revoke execute on function public.send_sms_telegram(jsonb) from public, anon, authenticated;
