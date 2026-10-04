-- =============================================================================
-- Push al registrar un movimiento
-- =============================================================================
-- movements INSERT -> trigger -> pg_net (HTTP asíncrono) -> Edge Function
-- `send-push` -> FCM HTTP v1.
--
-- * Sin secretos en el repo: la URL del proyecto y el secreto compartido con
--   la función se leen de Supabase Vault (ver README > Push).
-- * pg_net es asíncrono: la inserción del movimiento nunca espera ni falla por
--   la notificación (cualquier error queda como WARNING).
-- * `set app.skip_push = 'on'` desactiva el envío (lo usa seed.sql).
-- =============================================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.notify_movement_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url    text;
  v_secret text;
begin
  if coalesce(current_setting('app.skip_push', true), 'off') = 'on' then
    return new;
  end if;

  select decrypted_secret into v_url
    from vault.decrypted_secrets where name = 'project_url';
  select decrypted_secret into v_secret
    from vault.decrypted_secrets where name = 'push_webhook_secret';

  if v_url is null or v_secret is null then
    raise warning 'notify_movement_push: vault secrets project_url / push_webhook_secret no configurados';
    return new;
  end if;

  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/send-push',
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'movements',
      'record', to_jsonb(new)
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', v_secret
    ),
    timeout_milliseconds := 5000
  );
  return new;
exception when others then
  raise warning 'notify_movement_push failed: %', sqlerrm;
  return new;
end;
$$;

revoke execute on function public.notify_movement_push() from public, anon, authenticated;

create trigger movements_notify_push
  after insert on public.movements
  for each row execute function public.notify_movement_push();
