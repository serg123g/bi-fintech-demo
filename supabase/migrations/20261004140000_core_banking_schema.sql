-- =============================================================================
-- Core banking schema: perfiles, cuentas y movimientos
-- =============================================================================
-- Decisiones:
--   * El saldo de la cuenta es la suma de sus movimientos. Se mantiene
--     denormalizado en accounts.balance mediante trigger (lectura O(1) para el
--     home) y nunca lo escribe el cliente.
--   * Montos en numeric(14,2): nunca float para dinero.
--   * El segmento vive en el perfil y es la llave de la personalización (SDUI).
-- =============================================================================

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- profiles (1:1 con auth.users)
-- -----------------------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null check (char_length(full_name) between 2 and 120),
  segment     text not null default 'joven'
                check (segment in ('joven', 'pyme', 'premium')),
  created_at  timestamptz not null default now()
);

comment on table public.profiles is
  'Perfil del cliente. segment determina la experiencia personalizada.';

-- -----------------------------------------------------------------------------
-- accounts
-- -----------------------------------------------------------------------------
create table public.accounts (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  type           text not null check (type in ('ahorros', 'corriente')),
  number_masked  text not null check (number_masked ~ '^\*{4}[0-9]{4}$'),
  balance        numeric(14, 2) not null default 0,
  currency       char(3) not null default 'USD',
  created_at     timestamptz not null default now()
);

create index accounts_user_id_idx on public.accounts (user_id);

-- -----------------------------------------------------------------------------
-- movements
-- -----------------------------------------------------------------------------
create table public.movements (
  id           uuid primary key default gen_random_uuid(),
  account_id   uuid not null references public.accounts (id) on delete cascade,
  amount       numeric(14, 2) not null check (amount <> 0),
  description  text not null check (char_length(description) between 1 and 140),
  category     text not null default 'otros'
                 check (category in (
                   'ingreso', 'transferencia', 'comida', 'transporte',
                   'servicios', 'compras', 'salud', 'entretenimiento', 'otros'
                 )),
  created_at   timestamptz not null default now()
);

-- Listado paginado por cuenta, más recientes primero.
create index movements_account_created_idx
  on public.movements (account_id, created_at desc);

-- -----------------------------------------------------------------------------
-- Saldo consistente: cada movimiento ajusta el saldo de su cuenta.
-- -----------------------------------------------------------------------------
create or replace function public.apply_movement_to_balance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.accounts
       set balance = balance + new.amount
     where id = new.account_id;
  elsif tg_op = 'DELETE' then
    update public.accounts
       set balance = balance - old.amount
     where id = old.account_id;
  elsif tg_op = 'UPDATE' then
    update public.accounts
       set balance = balance - old.amount
     where id = old.account_id;
    update public.accounts
       set balance = balance + new.amount
     where id = new.account_id;
  end if;
  return null;
end;
$$;

create trigger movements_apply_balance
  after insert or update of amount, account_id or delete on public.movements
  for each row execute function public.apply_movement_to_balance();

-- -----------------------------------------------------------------------------
-- Alta automática al registrarse (onboarding)
-- La app envía full_name y segment en user_metadata durante signUp.
-- Se crea el perfil y una cuenta de ahorros en cero, de forma atómica.
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_segment text := coalesce(new.raw_user_meta_data ->> 'segment', 'joven');
  v_name    text := coalesce(
                      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
                      split_part(new.email, '@', 1)
                    );
begin
  if v_segment not in ('joven', 'pyme', 'premium') then
    v_segment := 'joven';
  end if;

  insert into public.profiles (id, full_name, segment)
  values (new.id, v_name, v_segment)
  on conflict (id) do nothing;

  insert into public.accounts (user_id, type, number_masked)
  values (
    new.id,
    'ahorros',
    '****' || lpad((floor(random() * 10000))::int::text, 4, '0')
  );

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
