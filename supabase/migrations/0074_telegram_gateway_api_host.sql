-- 0074: point the Telegram OTP hook at the Gateway *API* host.
--
-- 0038/0040 posted to `https://gateway.telegram.org/sendVerificationMessage`.
-- That host is the Gateway marketing/dashboard site, not the API: it answers
-- any path with the landing page — HTTP 200 and an HTML body. pg_net recorded
-- the 200 and moved on, the hook returned success, and Supabase told the
-- client "code sent", so the failure was completely silent: the user waited
-- for a Telegram message that was never requested.
--
-- The API lives at `https://gatewayapi.telegram.org` (see
-- https://core.telegram.org/gateway/api). Same token, same payload — only the
-- host was wrong.
--
-- Verify after applying: request a code, then
--   select created, status_code, content from net._http_response
--   order by created desc limit 1;
-- A working call returns JSON ({"ok":true,...}); the old bug returned HTML.

create or replace function public.send_sms_telegram(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
  v_phone text := event->'user'->>'phone';
  v_otp   text := event->'sms'->>'otp';
begin
  select value into v_token
    from private.app_secrets where name = 'telegram_gateway_token';

  if v_token is null or v_token = '' then
    return jsonb_build_object('error', jsonb_build_object(
      'http_code', 500,
      'message', 'telegram_gateway_token is not configured'));
  end if;
  if v_phone is null or v_otp is null then
    return jsonb_build_object('error', jsonb_build_object(
      'http_code', 400,
      'message', 'missing phone or otp in hook payload'));
  end if;

  if left(v_phone, 1) <> '+' then
    v_phone := '+' || v_phone;
  end if;

  perform net.http_post(
    url     := 'https://gatewayapi.telegram.org/sendVerificationMessage',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'Authorization', 'Bearer ' || v_token),
    -- `code` reuses Supabase's own OTP so verifyOtp() checks against the code
    -- the user actually received, rather than one Telegram would generate.
    body    := jsonb_build_object('phone_number', v_phone, 'code', v_otp)
  );

  return '{}'::jsonb;
end;
$$;

grant execute on function public.send_sms_telegram(jsonb) to supabase_auth_admin;
revoke execute on function public.send_sms_telegram(jsonb) from public, anon, authenticated;
