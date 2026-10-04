-- =============================================================================
-- Feature flags (TBD: el trabajo incompleto vive en main detrás de un flag)
-- y tokens de dispositivo para push (FCM).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- feature_flags
-- segment = null  -> aplica a todos los segmentos.
-- -----------------------------------------------------------------------------
create table public.feature_flags (
  key          text primary key check (key ~ '^[a-z][a-z0-9_]{1,63}$'),
  enabled      boolean not null default false,
  segment      text null check (segment in ('joven', 'pyme', 'premium')),
  description  text,
  updated_at   timestamptz not null default now()
);

comment on table public.feature_flags is
  'Flags remotos. Lectura para usuarios autenticados; escritura solo desde dashboard/service_role.';

-- -----------------------------------------------------------------------------
-- device_tokens
-- Un token pertenece a un único dispositivo; si otro usuario inicia sesión en
-- el mismo dispositivo, el token se reasigna (ver register_device_token).
-- -----------------------------------------------------------------------------
create table public.device_tokens (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  token       text not null unique check (char_length(token) between 20 and 4096),
  platform    text not null check (platform in ('android', 'ios', 'web')),
  updated_at  timestamptz not null default now(),
  primary key (user_id, token)
);

create index device_tokens_user_id_idx on public.device_tokens (user_id);

-- -----------------------------------------------------------------------------
-- RPC: registrar / refrescar token del usuario autenticado.
-- security definer para poder reasignar un token que pertenecía a otro usuario
-- (logout/login en el mismo teléfono) sin abrir una política UPDATE amplia.
-- -----------------------------------------------------------------------------
create or replace function public.register_device_token(
  p_token text,
  p_platform text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  delete from public.device_tokens
   where token = p_token
     and user_id <> v_uid;

  insert into public.device_tokens (user_id, token, platform, updated_at)
  values (v_uid, p_token, p_platform, now())
  on conflict (user_id, token)
  do update set platform = excluded.platform, updated_at = now();
end;
$$;

-- RPC: eliminar el token al cerrar sesión.
create or replace function public.unregister_device_token(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_tokens
   where token = p_token
     and user_id = auth.uid();
$$;
